class CategoryModel {
  final int id;
  final String name;
  final int? parentId;
  List<CategoryModel> subCategories; // Ağaç yapısı için

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    List<CategoryModel>? subCategories,
  }) : subCategories = subCategories ?? [];

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      name: json['name'] ?? "",
      parentId: json['parent'] != null ? json['parent']['id'] : null,
    );
  }
}
