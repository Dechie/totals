// Cross-bank transfer matching service.
//
// Detects pairs where a CREDIT in one bank corresponds to a DEBIT in another bank
// (e.g. Telebirr credit matched to a CBE debit, or an Awash credit matched to a
// Coopay debit).  The heuristic assumes the CREDIT's `creditor` field contains
// the source bank name and the amounts are equal within tolerance.
//
// Matching pipeline per CREDIT:
//   1. Identify the source bank from the creditor text (explicit alias rules first,
//      then token fallback via bank name / short name / codes).
//   2. Skip self-matches (same source and destination bank).
//   3. Search DEBITs in that source bank for equal amount + time window.
//   4. If a BankPairRule exists for this creditor/receiver combo, validate that
//      the banks align — reject if they don't.
//   5. Pick the closest-time match per CREDIT; each DEBIT can only be used once.
//
// The Telebirr-specific service (telebirr_bank_transfer_service.dart) is kept
// as-is; this generalised version replaces it in the providers.

import 'package:totals/models/bank.dart';
import 'package:totals/models/transaction.dart';
import 'package:totals/services/bank_transfer_rules.dart';

class CrossBankTransferMatch {
  final Transaction creditTransaction; // the incoming CREDIT (destination side)
  final Transaction debitTransaction;  // the outgoing DEBIT (source side)
  final Bank sourceBank;               // bank the money came from (DEBIT side)
  final Bank destinationBank;          // bank the money arrived at (CREDIT side)
  final Duration timeDelta;            // absolute time gap between the two

  CrossBankTransferMatch({
    required this.creditTransaction,
    required this.debitTransaction,
    required this.sourceBank,
    required this.destinationBank,
    required this.timeDelta,
  });
}

class CrossBankTransferService {
  static const Duration matchWindow = Duration(minutes: 10);
  static const double amountTolerance = 0.01;

  final BankTransferRules rules;

  CrossBankTransferService({BankTransferRules? rules})
      : rules = rules ?? const BankTransferRules();

  List<CrossBankTransferMatch> findMatches(
    List<Transaction> transactions,
    List<Bank> banks,
  ) {
    final banksById = {for (final bank in banks) bank.id: bank};
    final tokensByBankId = {
      for (final bank in banks) bank.id: _tokensForBank(bank),
    };

    // Group DEBITs by bank so we can quickly look up candidates later.
    final bankDebitsById = <int, List<Transaction>>{};
    for (final transaction in transactions) {
      final bankId = transaction.bankId;
      if (bankId == null) continue;
      if (transaction.type != 'DEBIT') continue;
      bankDebitsById.putIfAbsent(bankId, () => []).add(transaction);
    }

    // Every CREDIT with a non-empty creditor is a candidate transfer arrival.
    final candidateCredits = transactions.where((transaction) {
      return transaction.type == 'CREDIT' &&
          (transaction.creditor?.trim().isNotEmpty ?? false);
    }).toList();

    // Process newest credits first so we prefer closer time matches.
    candidateCredits.sort((a, b) {
      final timeA = _parseTime(a.time);
      final timeB = _parseTime(b.time);
      if (timeA == null && timeB == null) return 0;
      if (timeA == null) return 1;
      if (timeB == null) return -1;
      return timeB.compareTo(timeA);
    });

    final usedDebitReferences = <String>{};
    final matches = <CrossBankTransferMatch>[];

    for (final creditTx in candidateCredits) {
      final sender = creditTx.creditor?.trim();
      if (sender == null || sender.isEmpty) continue;

      // Step 1: work out which bank sent the money.
      final sourceBank = _bankFromSender(sender, banks, tokensByBankId, rules);
      if (sourceBank == null) continue;

      // Step 2: skip transfers inside the same bank (not cross-bank).
      if (creditTx.bankId == sourceBank.id) continue;

      final creditTime = _parseTime(creditTx.time);
      if (creditTime == null) continue;

      // Step 3: find a DEBIT in the source bank with matching amount and time.
      final candidates = bankDebitsById[sourceBank.id] ?? const [];
      Transaction? bestMatch;
      Duration? bestDelta;

      for (final debitTx in candidates) {
        if (usedDebitReferences.contains(debitTx.reference)) continue;
        if (!_amountMatches(creditTx.amount, debitTx.amount)) continue;

        final debitTime = _parseTime(debitTx.time);
        if (debitTime == null) continue;

        final delta = creditTime.difference(debitTime).abs();
        if (delta > matchWindow) continue;

        // Step 4: if a BankPairRule applies, verify the direction is correct.
        final pairRule = rules.matchPairRule(
          _normalizeToken(sender),
          debitTx.receiver != null ? _normalizeToken(debitTx.receiver!) : null,
        );
        if (pairRule != null) {
          if (pairRule.sourceBankId != sourceBank.id ||
              pairRule.destinationBankId != creditTx.bankId) {
            continue;
          }
        }

        // Step 5: prefer the DEBIT closest in time to the CREDIT.
        if (bestDelta == null || delta < bestDelta) {
          bestDelta = delta;
          bestMatch = debitTx;
        }
      }

      if (bestMatch != null && bestDelta != null) {
        usedDebitReferences.add(bestMatch.reference);
        final destinationBank = banksById[creditTx.bankId] ?? sourceBank;
        matches.add(
          CrossBankTransferMatch(
            creditTransaction: creditTx,
            debitTransaction: bestMatch,
            sourceBank: banksById[sourceBank.id] ?? sourceBank,
            destinationBank: destinationBank,
            timeDelta: bestDelta,
          ),
        );
      }
    }

    return matches;
  }

  static bool _amountMatches(double a, double b) {
    return (a - b).abs() <= amountTolerance;
  }

  static DateTime? _parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  // Identify the source bank from the creditor text.
  // Priority: explicit CreditorAlias rules → bank name/short name/code tokens.
  static Bank? _bankFromSender(
    String sender,
    List<Bank> banks,
    Map<int, Set<String>> tokensByBankId,
    BankTransferRules rules,
  ) {
    final normalizedSender = _normalizeToken(sender);

    // Check explicit aliases first (handles ambiguous or multi-word patterns).
    final aliasBankId = rules.matchCreditorToBank(normalizedSender);
    if (aliasBankId != null) {
      for (final bank in banks) {
        if (bank.id == aliasBankId) return bank;
      }
    }

    // Fall back to matching any token derived from the bank config.
    for (final bank in banks) {
      final tokens = tokensByBankId[bank.id];
      if (tokens == null || tokens.isEmpty) continue;
      for (final token in tokens) {
        if (token.isEmpty) continue;
        if (normalizedSender.contains(token)) {
          return bank;
        }
      }
    }
    return null;
  }

  // Build a set of normalised search tokens from a Bank definition.
  static Set<String> _tokensForBank(Bank bank) {
    final tokens = <String>{};
    tokens.add(_normalizeToken(bank.name));
    tokens.add(_normalizeToken(bank.shortName));
    for (final code in bank.codes) {
      tokens.add(_normalizeToken(code));
    }
    tokens.removeWhere((token) => token.length < 2);
    return tokens;
  }

  // Lowercase + strip non-alphanumeric characters for comparison.
  static String _normalizeToken(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
