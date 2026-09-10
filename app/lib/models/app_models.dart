class HighlightItem {
  final int paragraphIndex;
  String color; // 'yellow', 'green', 'pink'
  String note;
  String? bookTitle;

  HighlightItem({
    required this.paragraphIndex,
    required this.color,
    this.note = '',
    this.bookTitle,
  });

  factory HighlightItem.fromJson(Map<String, dynamic> json) => HighlightItem(
    paragraphIndex: json['paragraph_index'] is int ? json['paragraph_index'] : int.tryParse(json['paragraph_index'].toString()) ?? 0,
    color: json['color']?.toString() ?? 'yellow',
    note: json['note']?.toString() ?? '',
    bookTitle: json['book_title']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'paragraph_index': paragraphIndex,
    'color': color,
    'note': note,
    if (bookTitle != null) 'book_title': bookTitle,
  };
}

class CategoryItem {
  final int? id;
  final String name;
  final String slug;
  final int colorValue;

  CategoryItem({
    this.id,
    required this.name,
    required this.slug,
    required this.colorValue,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    int colorVal = 0xFF3E5C45;
    if (json['color_hex'] != null) {
      try {
        final hex = json['color_hex'].toString().replaceAll('#', '');
        if (hex.length == 6) {
          colorVal = int.parse('FF$hex', radix: 16);
        }
      } catch (_) {}
    }
    return CategoryItem(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? json['tag'] ?? '',
      colorValue: colorVal,
    );
  }
}

class CollectionItem {
  final int? id;
  final String name;
  final int colorValue;
  final String tag;
  final int booksCount;

  CollectionItem({
    this.id,
    required this.name,
    required this.colorValue,
    required this.tag,
    this.booksCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color_hex': '#${colorValue.toRadixString(16).padLeft(8, '0').substring(2)}',
    'tag': tag,
    'books_count': booksCount,
  };

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    int colorVal = 0xFF4B6B4A;
    if (json['color_hex'] != null) {
      try {
        final hex = json['color_hex'].toString().replaceAll('#', '');
        if (hex.length == 6) {
          colorVal = int.parse('FF$hex', radix: 16);
        }
      } catch (_) {}
    }
    return CollectionItem(
      id: json['id'],
      name: json['name'] ?? '',
      tag: json['tag'] ?? '',
      colorValue: colorVal,
      booksCount: json['books_count'] ?? 0,
    );
  }
}

class PlanItem {
  final String id;
  final String label;
  final String price;
  final String sub;
  final String? badge;
  final int? aiDailyLimit;
  final int? vocabLimit;
  final List<String> features;
  final Map<String, bool> permissions;
  final bool isFeatured;

  PlanItem({
    required this.id,
    required this.label,
    required this.price,
    required this.sub,
    this.badge,
    this.aiDailyLimit,
    this.vocabLimit,
    List<String>? features,
    Map<String, bool>? permissions,
    this.isFeatured = false,
  })  : features = features ?? const [],
        permissions = permissions ?? const {};

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    List<String> feats = [];
    if (json['features'] != null && json['features'] is List) {
      feats = (json['features'] as List)
          .where((f) => f != null)
          .map((f) => f.toString())
          .toList();
    }

    Map<String, bool> perms = {};
    if (json['feature_permissions'] != null && json['feature_permissions'] is Map) {
      (json['feature_permissions'] as Map).forEach((k, v) {
        perms[k.toString()] = v == true || v == 1;
      });
    }

    return PlanItem(
      id: json['slug']?.toString() ?? json['id']?.toString() ?? 'monthly',
      label: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      sub: json['billing_period']?.toString() ?? '',
      badge: json['badge']?.toString(),
      aiDailyLimit: json['ai_daily_limit'] is int ? json['ai_daily_limit'] : null,
      vocabLimit: json['vocab_limit'] is int ? json['vocab_limit'] : null,
      features: feats,
      permissions: perms,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
    );
  }
}
