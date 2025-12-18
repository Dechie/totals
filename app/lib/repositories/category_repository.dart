import 'package:sqflite/sqflite.dart';
import 'package:totals/database/database_helper.dart';
import 'package:totals/models/category.dart';

class CategoryRepository {
  Future<void> ensureSeeded() async {
    final db = await DatabaseHelper.instance.database;
    final batch = db.batch();
    for (final category in BuiltInCategories.all) {
      batch.insert(
        'categories',
        {
          'name': category.name,
          'essential': category.essential ? 1 : 0,
          'iconKey': category.iconKey,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      batch.update(
        'categories',
        {
          'essential': category.essential ? 1 : 0,
          'iconKey': category.iconKey,
        },
        where: 'name = ?',
        whereArgs: [category.name],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getCategories() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'categories',
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Category.fromDb).toList();
  }
}
