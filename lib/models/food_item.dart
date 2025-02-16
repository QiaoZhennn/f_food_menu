class FoodItem {
  final String name;
  final List<String> ingredients;
  final double price;

  FoodItem({
    required this.name,
    required this.ingredients,
    required this.price,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      name: json['name'],
      ingredients: (json['ingredients'] as List?)?.cast<String>() ?? [],
      price: json['price'].toDouble(),
    );
  }
}
