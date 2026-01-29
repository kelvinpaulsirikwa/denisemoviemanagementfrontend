class Category {
  final int id;
  final String name;
  final String description;
  final String createdAt;
  final String updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class CategoryResponse {
  final bool success;
  final List<Category> categories;
  final Pagination pagination;

  CategoryResponse({
    required this.success,
    required this.categories,
    required this.pagination,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      success: json['success'] ?? false,
      categories: (json['data']['categories'] as List?)
          ?.map((category) => Category.fromJson(category))
          .toList() ?? [],
      pagination: Pagination.fromJson(json['data']['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  Pagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }
}
