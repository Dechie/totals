import 'package:flutter/material.dart';

IconData iconForCategoryKey(String? iconKey) {
  switch (iconKey) {
    case 'payments':
      return Icons.payments_rounded;
    case 'gift':
      return Icons.card_giftcard_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'shopping_cart':
      return Icons.shopping_cart_rounded;
    case 'directions_car':
      return Icons.directions_car_rounded;
    case 'restaurant':
      return Icons.restaurant_rounded;
    case 'checkroom':
      return Icons.checkroom_rounded;
    case 'health':
      return Icons.health_and_safety_rounded;
    case 'phone':
      return Icons.phone_android_rounded;
    case 'request_quote':
      return Icons.request_quote_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'more_horiz':
      return Icons.more_horiz_rounded;
    default:
      return Icons.category_rounded;
  }
}

