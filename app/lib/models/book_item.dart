import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BookItem {
  final int? id;
  final int? userId;
  final bool isPublic;
  final String title;
  final String? author;
  final String? meta;
  final Color color;
  int? progress;
  String tag;
  final List<String> paragraphs;
  bool isFavorite;
  DateTime? lastReadAt;

  BookItem({
    this.id,
    this.userId,
    this.isPublic = true,
    required this.title,
    this.author,
    this.meta,
    required this.color,
    this.progress,
    required this.tag,
    this.paragraphs = const [],
    this.isFavorite = false,
    this.lastReadAt,
  });

  factory BookItem.fromJson(Map<String, dynamic> json) {
    Color col = AppColors.moss;
    final cover = json['cover_color']?.toString().toLowerCase() ?? 'forest';
    if (cover == 'gold') {
      col = AppColors.gold;
    } else if (cover == 'navy') {
      col = AppColors.blueTheme;
    } else if (cover == 'rose' || cover == 'crimson') {
      col = AppColors.plum;
    } else if (cover == 'paper') {
      col = const Color(0xFF8B5A2B);
    }

    List<String> paras = [];
    if (json['paragraphs'] != null && json['paragraphs'] is List) {
      paras = (json['paragraphs'] as List)
          .map((p) => p is Map ? (p['content']?.toString() ?? '') : p.toString())
          .where((p) => p.isNotEmpty)
          .toList();
    }

    DateTime? lastRead;
    if (json['last_read_at'] != null) {
      lastRead = DateTime.tryParse(json['last_read_at'].toString());
    } else if (json['updated_at'] != null) {
      lastRead = DateTime.tryParse(json['updated_at'].toString());
    }

    final rawUserId = json['user_id'];
    final userId = rawUserId is int ? rawUserId : int.tryParse(rawUserId?.toString() ?? '');
    final isPublic = json['is_public'] == true || json['is_public'] == 1 || rawUserId == null;

    return BookItem(
      id: json['id'],
      userId: userId,
      isPublic: isPublic,
      title: json['title'] ?? 'Untitled Book',
      author: json['author'] ?? 'Unknown Author',
      meta: json['read_time'] ?? json['meta'] ?? '5 min read',
      color: col,
      progress: json['progress'] is int ? json['progress'] : null,
      tag: json['category'] ?? json['tag'] ?? 'imported',
      paragraphs: paras,
      isFavorite: json['is_favorite'] == true,
      lastReadAt: lastRead,
    );
  }

  Map<String, dynamic> toJson() {
    String cover = 'forest';
    if (color == AppColors.gold) cover = 'gold';
    if (color == AppColors.blueTheme) cover = 'navy';
    if (color == AppColors.plum) cover = 'rose';

    return {
      'id': id,
      if (userId != null) 'user_id': userId,
      'is_public': isPublic,
      'title': title,
      'author': author,
      'read_time': meta,
      'cover_color': cover,
      'progress': progress,
      'category': tag,
      'paragraphs': paragraphs,
      'is_favorite': isFavorite,
      'last_read_at': lastReadAt?.toUtc().toIso8601String(),
    };
  }
}
