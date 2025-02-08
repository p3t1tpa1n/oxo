// lib/models/profile.dart
class Profile {
  final String username;
  final String password;
  final String displayName;
  final String email;

  const Profile({
    required this.username,
    required this.password,
    required this.displayName,
    required this.email,
  });
}

const List<Profile> profilesList = [
  Profile(username: 'user1', password: 'pass1', displayName: 'Alice', email: 'alice@example.com'),
  Profile(username: 'user2', password: 'pass2', displayName: 'Bob', email: 'bob@example.com'),
  Profile(username: 'user3', password: 'pass3', displayName: 'Charlie', email: 'charlie@example.com'),
  Profile(username: 'user4', password: 'pass4', displayName: 'Diana', email: 'diana@example.com'),
];

Profile? currentProfile;