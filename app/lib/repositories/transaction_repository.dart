import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:totals/database/database_helper.dart';
import 'package:totals/models/transaction.dart';

class TransactionRepository {
  Future<List<Transaction>> getTransactions() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query('transactions', orderBy: 'time DESC, id DESC');

    return maps.map<Transaction>((map) {
      return Transaction.fromJson({
        'amount': map['amount'],
        'reference': map['reference'],
        'creditor': map['creditor'],
        'receiver': map['receiver'],
        'time': map['time'],
        'status': map['status'],
        'currentBalance': map['currentBalance'],
        'bankId': map['bankId'],
        'type': map['type'],
        'transactionLink': map['transactionLink'],
        'accountNumber': map['accountNumber'],
      });
    }).toList();
  }

  Future<void> saveTransaction(Transaction transaction) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'transactions',
      {
        'amount': transaction.amount,
        'reference': transaction.reference,
        'creditor': transaction.creditor,
        'receiver': transaction.receiver,
        'time': transaction.time,
        'status': transaction.status,
        'currentBalance': transaction.currentBalance,
        'bankId': transaction.bankId,
        'type': transaction.type,
        'transactionLink': transaction.transactionLink,
        'accountNumber': transaction.accountNumber,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveAllTransactions(List<Transaction> transactions) async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();

    for (var transaction in transactions) {
      batch.insert(
        'transactions',
        {
          'amount': transaction.amount,
          'reference': transaction.reference,
          'creditor': transaction.creditor,
          'receiver': transaction.receiver,
          'time': transaction.time,
          'status': transaction.status,
          'currentBalance': transaction.currentBalance,
          'bankId': transaction.bankId,
          'type': transaction.type,
          'transactionLink': transaction.transactionLink,
          'accountNumber': transaction.accountNumber,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> clearAll() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('transactions');
  }

  /// Delete transactions associated with an account
  /// Uses the same matching logic as TransactionProvider to identify transactions
  Future<void> deleteTransactionsByAccount(String accountNumber, int bank) async {
    final db = await DatabaseHelper.instance.database;
    
    // For banks that match by bankId only (Awash=2, Telebirr=6), delete all transactions for that bank
    if (bank == 2 || bank == 6) {
      await db.delete(
        'transactions',
        where: 'bankId = ?',
        whereArgs: [bank],
      );
      return;
    }
    
    // For other banks, match by accountNumber substring logic
    String? accountSuffix;
    
    if (bank == 1 && accountNumber.length >= 4) {
      // CBE: last 4 digits
      accountSuffix = accountNumber.substring(accountNumber.length - 4);
    } else if (bank == 4 && accountNumber.length >= 3) {
      // Dashen: last 3 digits
      accountSuffix = accountNumber.substring(accountNumber.length - 3);
    } else if (bank == 3 && accountNumber.length >= 2) {
      // Bank of Abyssinia: last 2 digits
      accountSuffix = accountNumber.substring(accountNumber.length - 2);
    }
    
    if (accountSuffix != null) {
      // Delete transactions where bankId matches and accountNumber ends with the suffix
      // Using SQL LIKE pattern matching to match the suffix at the end
      await db.delete(
        'transactions',
        where: 'bankId = ? AND accountNumber IS NOT NULL AND accountNumber LIKE ?',
        whereArgs: [bank, '%$accountSuffix'],
      );
    } else {
      // Fallback: delete all transactions for this bank (except NULL accountNumber ones)
      await db.delete(
        'transactions',
        where: 'bankId = ? AND accountNumber IS NOT NULL',
        whereArgs: [bank],
      );
    }
  }
}
