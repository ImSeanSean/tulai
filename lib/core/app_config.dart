enum UserType { student, teacher, admin, none }

enum FormLanguage { english, filipino, none }

class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  UserType? userType;
  FormLanguage? formLanguage;
}
