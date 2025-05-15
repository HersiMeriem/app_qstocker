import 'package:app_qstocker/models/client_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get user => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

//login 

Future<User?> signInWithEmailAndPassword(String email, String password) async {
  try {
    UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Aucun utilisateur trouvé avec ces identifiants',
      );
    }

    final role = await _getUserRole(userCredential.user!.uid);
    if (role != 'client') {
      await signOut();
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'Seuls les clients peuvent se connecter via cette application',
      );
    }

    await _updateLastLogin(userCredential.user!.uid);
    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
      throw FirebaseAuthException(
        code: e.code,
        message: 'Email ou mot de passe incorrect',
      );
    }
    _logError('Erreur de connexion', e);
    rethrow;
  }
}



 //register 

  Future<User?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String gender,
    required String birthDate,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // 1. Validation des entrées
      if (email.isEmpty || password.isEmpty || fullName.isEmpty) {
        throw FirebaseAuthException(
          code: 'required-fields',
          message: 'Veuillez remplir tous les champs obligatoires',
        );
      }

      if (password.length < 6) {
        throw FirebaseAuthException(
          code: 'weak-password', 
          message: 'Le mot de passe doit contenir au moins 6 caractères',
        );
      }

      // 2. Vérification de l'email
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Un compte existe déjà avec cet email',
        );
      }

      // 3. Création du compte Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'La création du compte a échoué',
        );
      }

      // 4. Mise à jour du profil
      await user.updateDisplayName(fullName.trim());

      // 5. Enregistrement dans la base de données
      final userData = {
        'uid': user.uid,
        'email': email.trim(),
        'fullName': fullName.trim(),
        'gender': gender,
        'birthDate': birthDate,
        'createdAt': ServerValue.timestamp,
        'status': 'pending',
        'role': 'client',
        ...?additionalData,
      };

      await _database.child('clients').child(user.uid).set(userData);

      return user;

    } on FirebaseAuthException {
      // Ré-émettre les erreurs Firebase avec des messages clairs
      rethrow;
    } catch (e, stack) {
      debugPrint('Erreur d\'inscription: $e\n$stack');
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: 'Une erreur technique est survenue. Veuillez réessayer plus tard.',
      );
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.additionalUserInfo!.isNewUser) {
        await _database.child('clients').child(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email!,
          'fullName': userCredential.user!.displayName ?? 'Utilisateur Google',
          'role': 'client',
          'gender': 'Non spécifié',
          'birthDate': '',
          'createdAt': ServerValue.timestamp,
          'lastLogin': ServerValue.timestamp,
          'notificationsEnabled': true,
          'language': 'Français',
          'status': 'approved',
        });
      } else {
        final role = await _getUserRole(userCredential.user!.uid);
        if (role != 'client') {
          await signOut();
          throw FirebaseAuthException(
            code: 'permission-denied',
            message: 'Seuls les clients peuvent se connecter via cette application',
          );
        }
      }

      await _updateLastLogin(userCredential.user!.uid);
      return userCredential.user;
    } catch (e) {
      _logError('Erreur lors de la connexion avec Google', e);
      rethrow;
    }
  }


//deconnexion 

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      _logError('Erreur lors de la déconnexion', e);
      rethrow;
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? photoUrl,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      final updates = <String, dynamic>{};
      
      if (displayName != null) {
        await user.updateDisplayName(displayName);
        updates['fullName'] = displayName;
      }
      
      if (photoUrl != null) {
        await user.updatePhotoURL(photoUrl);
        updates['photoURL'] = photoUrl;
      }
      
      if (additionalData != null) {
        updates.addAll(additionalData);
      }
      
      if (updates.isNotEmpty) {
        await _database.child('clients').child(user.uid).update(updates);
      }
    } catch (e) {
      _logError('Erreur lors de la mise à jour du profil', e);
      rethrow;
    }
  }

  Future<void> updateEmail(String newEmail) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      await user.verifyBeforeUpdateEmail(newEmail);
      await _database.child('clients').child(user.uid).update({
        'email': newEmail,
      });
    } catch (e) {
      _logError('Erreur lors de la mise à jour de l\'email', e);
      rethrow;
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      final ref = _storage.ref('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _logError('Erreur lors de l\'upload de l\'image', e);
      rethrow;
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      if (user.providerData.any((info) => info.providerId == 'password')) {
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);
      }

      await user.updatePassword(newPassword);
    } catch (e) {
      _logError('Erreur lors du changement de mot de passe', e);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logError('Erreur lors de la réinitialisation du mot de passe', e);
      rethrow;
    }
  }

  Future<Client> getCurrentUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      final snapshot = await _database.child('clients').child(user.uid).get();
      if (!snapshot.exists) throw 'Données utilisateur non trouvées';

      return Client.fromMap(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      _logError('Erreur lors de la récupération des données utilisateur', e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      final snapshot = await _database.child('clients').child(user.uid).get();
      if (!snapshot.exists) throw 'Données utilisateur non trouvées';

      return Map<String, dynamic>.from(snapshot.value as Map);
    } catch (e) {
      _logError('Erreur de récupération des données', e);
      rethrow;
    }
  }

  Future<void> updateProfilePhoto(String url) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      await user.updatePhotoURL(url);
      await _database.child('clients').child(user.uid).update({
        'photoURL': url,
      });
    } catch (e) {
      _logError('Erreur lors de la mise à jour de la photo de profil', e);
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      await user.updateDisplayName(name);
      await _database.child('clients').child(user.uid).update({
        'fullName': name,
      });
    } catch (e) {
      _logError('Erreur lors de la mise à jour du nom d\'affichage', e);
      rethrow;
    }
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      await _database.child('clients').child(user.uid).update(data);
    } catch (e) {
      _logError('Erreur lors de la mise à jour des données utilisateur', e);
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'Utilisateur non connecté';

      await _database.child('clients').child(user.uid).remove();
      await user.delete();
    } catch (e) {
      _logError('Erreur lors de la suppression du compte', e);
      rethrow;
    }
  }

  Future<String?> _getUserRole(String uid) async {
    try {
      final snapshot = await _database.child('clients').child(uid).child('role').get();
      return snapshot.value as String?;
    } catch (e) {
      _logError('Erreur lors de la récupération du rôle', e);
      return null;
    }
  }

  Future<void> _updateLastLogin(String uid) async {
    try {
      await _database.child('clients').child(uid).update({
        'lastLogin': ServerValue.timestamp,
      });
    } catch (e) {
      _logError('Erreur lors de la mise à jour de la dernière connexion', e);
    }
  }

  void _logError(String context, dynamic error) {
    if (kDebugMode) {
      debugPrint('$context: ${error.toString()}');
      if (error is FirebaseAuthException) {
        debugPrint('Code: ${error.code} | Message: ${error.message}');
      }
    }
  }
}