class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  String get id => uid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
