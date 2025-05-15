class Client {
  String uid;
  String email;
  String fullName;
  String role;
  String gender;
  String birthDate;
  DateTime createdAt;
  DateTime lastLogin;
  bool notificationsEnabled;
  String language;
  String? photoURL;
  final String status; // Ajoutez ce champ


  Client({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.gender,
    required this.birthDate,
    required this.createdAt,
    required this.lastLogin,
    required this.notificationsEnabled,
    required this.language,
    this.photoURL,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'gender': gender,
      'birthDate': birthDate,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
      'language': language,
      'photoURL': photoURL,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      uid: map['uid'],
      email: map['email'],
      fullName: map['fullName'],
      role: map['role'],
      gender: map['gender'],
      birthDate: map['birthDate'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: DateTime.parse(map['lastLogin']),
      notificationsEnabled: map['notificationsEnabled'],
      language: map['language'],
      photoURL: map['photoURL'],
    );
  }
}
