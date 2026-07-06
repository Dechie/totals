import 'package:totals/models/transaction.dart';
import 'package:totals/services/auto_categorization_service.dart';
import 'package:totals/services/enrichment_pipeline.dart';
import 'package:totals/services/notification_settings_service.dart';

// Pipeline enricher that applies auto-categorization rules.
//
// Runs only when auto-categorization is enabled and the transaction
// doesn't already have a category set. The category is resolved via
// AutoCategorizationService which checks user-defined rules based on
// the transaction's counterparty and flow (income / expense).
class CategorizerEnricher extends TransactionEnricher {
  @override
  Future<Transaction> enrich(Transaction transaction, String rawMessage) async {
    if (transaction.categoryId != null) return transaction;

    final enabled = await NotificationSettingsService.instance
        .isAutoCategorizationEnabled();
    if (!enabled) return transaction;

    final categoryId =
        await AutoCategorizationService.instance.getCategoryForTransaction(
      type: transaction.type,
      receiver: transaction.receiver,
      creditor: transaction.creditor,
    );
    if (categoryId == null) return transaction;

    return transaction.copyWith(categoryId: categoryId);
  }
}
