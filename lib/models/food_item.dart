class FoodItem {
  final String name;
  final List<String> ingredients;
  final String drinkFlavor;
  final double? price;

  FoodItem({
    required this.name,
    required this.ingredients,
    this.drinkFlavor = '',
    this.price,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'] as String,
      ingredients: (json['ingredients'] as List?)?.cast<String>() ?? [],
      drinkFlavor: json['drinkFlavor'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble(),
    );
  }
}
