class Category {
  final int? id;
  final String name;
  final bool essential;
  final String? iconKey;
  final String? description;

  const Category({
    this.id,
    required this.name,
    required this.essential,
    this.iconKey,
    this.description,
  });

  factory Category.fromDb(Map<String, dynamic> row) {
    return Category(
      id: row['id'] as int?,
      name: (row['name'] as String?) ?? '',
      essential: (row['essential'] as int? ?? 0) == 1,
      iconKey: row['iconKey'] as String?,
      description: row['description'] as String?,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'name': name,
      'essential': essential ? 1 : 0,
      'iconKey': iconKey,
      'description': description,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    bool? essential,
    String? iconKey,
    String? description,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      essential: essential ?? this.essential,
      iconKey: iconKey ?? this.iconKey,
      description: description ?? this.description,
    );
  }
}

class BuiltInCategories {
  static const List<Category> all = [
    Category(
      name: 'Salary',
      essential: true,
      iconKey: 'payments',
      description: 'Income from salary or wages',
    ),
    Category(
      name: 'Gifts',
      essential: false,
      iconKey: 'gift',
      description: 'Gifts received or given',
    ),
    Category(
      name: 'Rent',
      essential: true,
      iconKey: 'home',
      description: 'Housing rent and lease payments',
    ),
    Category(
      name: 'Utilities',
      essential: true,
      iconKey: 'bolt',
      description: 'Electricity, water, internet, and bills',
    ),
    Category(
      name: 'Groceries',
      essential: true,
      iconKey: 'shopping_cart',
      description: 'Food and household essentials',
    ),
    Category(
      name: 'Transport',
      essential: true,
      iconKey: 'directions_car',
      description: 'Taxi, fuel, fares, and transport',
    ),
    Category(
      name: 'Eating outside',
      essential: false,
      iconKey: 'restaurant',
      description: 'Restaurants, cafes, and takeaway',
    ),
    Category(
      name: 'Clothing',
      essential: false,
      iconKey: 'checkroom',
      description: 'Clothes, shoes, and accessories',
    ),
    Category(
      name: 'Health',
      essential: true,
      iconKey: 'health',
      description: 'Medical, pharmacy, and health spending',
    ),
    Category(
      name: 'Airtime',
      essential: true,
      iconKey: 'phone',
      description: 'Mobile airtime and data bundles',
    ),
    Category(
      name: 'Loan',
      essential: true,
      iconKey: 'request_quote',
      description: 'Loan payments and interest',
    ),
    Category(
      name: 'Beauty',
      essential: false,
      iconKey: 'spa',
      description: 'Salon, grooming, and personal care',
    ),
    Category(
      name: 'Misc',
      essential: false,
      iconKey: 'more_horiz',
      description: 'Anything that doesn’t fit other categories',
    ),
  ];
}
