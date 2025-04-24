import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class GroupNoteModel extends Equatable {
  final String id;
  final String groupId;
  final String title;
  final String content;
  final String createdBy; // User ID of the creator
  final DateTime createdAt;
  final List<String> tags;
  final List<CommentModel> comments;

  const GroupNoteModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.content,
    required this.createdBy,
    required this.createdAt,
    this.tags = const [],
    this.comments = const [],
  });

  GroupNoteModel copyWith({
    String? id,
    String? groupId,
    String? title,
    String? content,
    String? createdBy,
    DateTime? createdAt,
    List<String>? tags,
    List<CommentModel>? comments,
  }) {
    return GroupNoteModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      content: content ?? this.content,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'title': title,
      'content': content,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'tags': tags,
      'comments': comments.map((c) => c.toJson()).toList(),
    };
  }

  factory GroupNoteModel.fromJson(Map<String, dynamic> json, String id) {
    return GroupNoteModel(
      id: id,
      groupId: json['groupId'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      comments: (json['comments'] as List<dynamic>?)
          ?.map((c) => CommentModel.fromJson(c as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    groupId,
    title,
    content,
    createdBy,
    createdAt,
    tags,
    comments,
  ];
}

class CommentModel extends Equatable {
  final String userId; // User ID of the commenter
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.userId,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      userId: json['userId'] ?? '',
      content: json['content'] ?? '',
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [userId, content, createdAt];
}