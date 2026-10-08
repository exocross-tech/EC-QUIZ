class AvatarPreset {
  final String id;
  final String emoji;
  final String name;

  const AvatarPreset({
    required this.id,
    required this.emoji,
    required this.name,
  });
}

class AppConstants {
  static const String appName = 'Quiz Clash';
  static const String webHostingUrl = 'https://quiz-game-app-3c75d.web.app';

  // Base64 & Firestore document limits
  // Spark plan Firestore: document max size is 1 MiB (1,048,576 bytes).
  // A single compressed image is capped at 200 KB (~273 KB base64 string).
  static const int maxImageSizeBytes = 200 * 1024; // 200 KB
  static const int maxDocSizeBytes = 1000 * 1024; // Safe ceiling below 1 MiB

  // Fun emoji badges chosen for avatars
  static const List<AvatarPreset> defaultAvatarPresets = [
    AvatarPreset(id: 'lion', emoji: '🦁', name: 'Lion'),
    AvatarPreset(id: 'fox', emoji: '🦊', name: 'Fox'),
    AvatarPreset(id: 'rocket', emoji: '🚀', name: 'Rocket'),
    AvatarPreset(id: 'lightning', emoji: '⚡', name: 'Bolt'),
    AvatarPreset(id: 'crown', emoji: '👑', name: 'Crown'),
    AvatarPreset(id: 'target', emoji: '🎯', name: 'Bullseye'),
    AvatarPreset(id: 'fire', emoji: '🔥', name: 'Fire'),
    AvatarPreset(id: 'star', emoji: '⭐', name: 'Star'),
    AvatarPreset(id: 'wizard', emoji: '🧙‍♂️', name: 'Wizard'),
    AvatarPreset(id: 'ninja', emoji: '🥷', name: 'Ninja'),
  ];
}
