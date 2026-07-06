// Central store for cross-bank transfer matching rules.
//
// Two categories:
//   CreditorAlias   — maps a creditor text substring to a bank ID (e.g. "cbe" → 3).
//                     Checked before the generic token fallback in CrossBankTransferService.
//   BankPairRule    — pairs a creditor-hint with a receiver-hint to confirm a known
//                     source→destination transfer direction. When both sides match,
//                     the service rejects any candidate pair that doesn't align.
//
// Rules are intentionally kept separate from bank config so they can be extended
// without touching JSON definitions.

class CreditorAlias {
  final String pattern; // normalized substring to match in the creditor text
  final int bankId;     // the bank the creditor text implies

  const CreditorAlias({required this.pattern, required this.bankId});
}

class BankPairRule {
  final int sourceBankId;      // bank where the DEBIT lives
  final int destinationBankId; // bank where the CREDIT lives
  final String? creditorHint;  // expected substring in the CREDIT's creditor (normalized)
  final String? receiverHint;  // expected substring in the DEBIT's receiver (normalized)

  const BankPairRule({
    required this.sourceBankId,
    required this.destinationBankId,
    this.creditorHint,
    this.receiverHint,
  });
}

class BankTransferRules {
  final List<CreditorAlias> creditorAliases;
  final List<BankPairRule> bankPairRules;

  const BankTransferRules({
    this.creditorAliases = _defaultCreditorAliases,
    this.bankPairRules = _defaultBankPairRules,
  });

  // Look up a bank ID from the normalized creditor text.
  // Returns the first matching alias, or null if none match.
  int? matchCreditorToBank(String normalizedCreditor) {
    for (final alias in creditorAliases) {
      if (normalizedCreditor.contains(alias.pattern)) {
        return alias.bankId;
      }
    }
    return null;
  }

  // Find the first BankPairRule whose hints match both the creditor text
  // (from the CREDIT) and the receiver text (from the DEBIT).
  // Returns null when no rule covers this pair.
  BankPairRule? matchPairRule(
    String? normalizedCreditor,
    String? normalizedReceiver,
  ) {
    for (final rule in bankPairRules) {
      final creditorOk = rule.creditorHint == null ||
          (normalizedCreditor != null &&
              normalizedCreditor.contains(rule.creditorHint!));
      final receiverOk = rule.receiverHint == null ||
          (normalizedReceiver != null &&
              normalizedReceiver.contains(rule.receiverHint!));
      if (creditorOk && receiverOk) {
        return rule;
      }
    }
    return null;
  }

  static const _defaultCreditorAliases = <CreditorAlias>[];
  static const _defaultBankPairRules = <BankPairRule>[];
}
