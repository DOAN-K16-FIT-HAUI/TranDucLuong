import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool? isDarkMode;
  final String? language;
  final String? loginMethod;

  const UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isDarkMode,
    this.language,
    this.loginMethod,
  });

  @override
  List<Object?> get props =>
      [id, email, displayName, photoUrl, isDarkMode, language, loginMethod];

  @override
  String toString() {
    return 'UserModelEntity(id: $id, email: $email, displayName: $displayName, photoUrl: $photoUrl), isDarkMode: $isDarkMode, language: $language, loginMethod: $loginMethod)';
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isDarkMode,
    String? language,
    String? loginMethod,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      loginMethod: loginMethod ?? this.loginMethod,
    );
  }
}