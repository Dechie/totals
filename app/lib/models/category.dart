class Category {
  final int? id;
  final String name;
  final bool essential;
  final String? iconKey;

  const Category({
    this.id,
    required this.name,
    required this.essential,
    this.iconKey,
  });

  factory Category.fromDb(Map<String, dynamic> row) {
    return Category(
      id: row['id'] as int?,
      name: (row['name'] as String?) ?? '',
      essential: (row['essential'] as int? ?? 0) == 1,
      iconKey: row['iconKey'] as String?,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'essential': essential ? 1 : 0,
      'iconKey': iconKey,
    };
  }
}

class BuiltInCategories {
  static const List<Category> all = [
    Category(name: 'Salary', essential: true, iconKey: 'payments'),
    Category(name: 'Gifts', essential: false, iconKey: 'gift'),
    Category(name: 'Rent', essential: true, iconKey: 'home'),
    Category(name: 'Utilities', essential: true, iconKey: 'bolt'),
    Category(name: 'Groceries', essential: true, iconKey: 'shopping_cart'),
    Category(name: 'Transport', essential: true, iconKey: 'directions_car'),
    Category(name: 'Eating outside', essential: false, iconKey: 'restaurant'),
    Category(name: 'Clothing', essential: false, iconKey: 'checkroom'),
    Category(name: 'Health', essential: true, iconKey: 'health'),
    Category(name: 'Airtime', essential: true, iconKey: 'phone'),
    Category(name: 'Loan', essential: true, iconKey: 'request_quote'),
    Category(name: 'Beauty', essential: false, iconKey: 'spa'),
    Category(name: 'Misc', essential: false, iconKey: 'more_horiz'),
  ];
}
