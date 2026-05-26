import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class UserProvider extends ChangeNotifier {
  String? _selectedAvatar;
  String? _userId;
  String? _username;
  bool _isLoading = false;
  List<String> _following = [];
  List<String> _followers = [];
  DateTime? _joinedAt;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? get selectedAvatar => _selectedAvatar;
  String? get userId => _userId;
  String? get username => _username;
  bool get isAuthenticated => _userId != null;
  bool get isLoading => _isLoading;
  List<String> get following => _following;
  List<String> get followers => _followers;
  DateTime? get joinedAt => _joinedAt;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    
    User? currentUser = _auth.currentUser;
    
    if (currentUser != null) {
      _userId = currentUser.uid;
      _username = currentUser.displayName ?? 'User';
      
      _selectedAvatar = prefs.getString('avatar');
      _selectedAvatar = prefs.getString('avatar');
      await _syncFromFirestore(currentUser.uid);
    } else {
      _userId = null;
      _username = null;
    }
    
    notifyListeners();
  }

  Future<void> _syncFromFirestore(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get().timeout(const Duration(seconds: 5));
      if (doc.exists) {
        final data = doc.data()!;
        _username = data['username'] ?? _username;
        _selectedAvatar = data['avatar'] ?? _selectedAvatar;
        
        if (data['following'] != null) {
          _following = List<String>.from(data['following']);
        }
        if (data['followers'] != null) {
          _followers = List<String>.from(data['followers']);
        }

        final ts = data['createdAt'];
        if (ts is Timestamp) _joinedAt = ts.toDate();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', _username!);
        if (_selectedAvatar != null) await prefs.setString('avatar', _selectedAvatar!);
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  Future<String?> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      if (userCred.user != null) {
        _userId = userCred.user!.uid;
        _username = userCred.user!.displayName ?? 'User';
        await _syncFromFirestore(_userId!);
        _isLoading = false;
        notifyListeners();
        return null; // success
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred';
    }
    _isLoading = false;
    notifyListeners();
    return 'Unknown login error';
  }

  Future<String?> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCred.user != null) {
        await userCred.user!.updateDisplayName(username);
        _userId = userCred.user!.uid;
        _username = username;
        
        try {
          await _db.collection('users').doc(_userId).set({
            'username': username,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 5));
        } catch (e) {
          debugPrint('Failed to set user document: $e');
        }
        
        _isLoading = false;
        notifyListeners();
        return null; // success
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred';
    }
    _isLoading = false;
    notifyListeners();
    return 'Unknown registration error';
  }
  
  Future<String?> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (kIsWeb) {
        // Web Flow
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final userCred = await _auth.signInWithPopup(googleProvider);
        if (userCred.user != null) {
          return await _handleSuccessfulGoogleAuth(userCred);
        }
      } else {
        // Mobile Flow
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _isLoading = false;
          notifyListeners();
          return 'Sign-in aborted';
        }
        
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        
        final userCred = await _auth.signInWithCredential(credential);
        if (userCred.user != null) {
          return await _handleSuccessfulGoogleAuth(userCred);
        }
      }
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      return e.message;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Google Sign-In failed: $e';
    }
    _isLoading = false;
    notifyListeners();
    return 'Unknown Google Sign-In error';
  }

  Future<String?> _handleSuccessfulGoogleAuth(UserCredential userCred) async {
    _userId = userCred.user!.uid;
    _username = userCred.user!.displayName ?? 'Google User';
    
    final doc = await _db.collection('users').doc(_userId).get().timeout(const Duration(seconds: 5));
    if (!doc.exists) {
      try {
        await _db.collection('users').doc(_userId).set({
          'username': _username,
          'email': userCred.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Failed to set user document: $e');
      }
    } else {
      await _syncFromFirestore(_userId!);
    }
    
    _isLoading = false;
    notifyListeners();
    return null; // success
  }


  Future<void> logout() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    _userId = null;
    _username = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('username');
    
    notifyListeners();
  }

  Future<void> setAvatar(String? avatar) async {
    _selectedAvatar = avatar;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (avatar != null) {
      await prefs.setString('avatar', avatar);
    } else {
      await prefs.remove('avatar');
    }
    
    if (_userId != null) {
      try {
        await _db.collection('users').doc(_userId).update({'avatar': avatar ?? ''});
      } catch (e) {
        debugPrint('Error updating avatar in Firestore: $e');
      }
    }
  }

  Future<void> toggleFollow(String targetUserId) async {
    if (_userId == null) return;
    
    final isFollowing = _following.contains(targetUserId);
    
    if (isFollowing) {
      _following.remove(targetUserId);
      notifyListeners();
      
      try {
        await _db.collection('users').doc(_userId).set({
          'following': FieldValue.arrayRemove([targetUserId])
        }, SetOptions(merge: true));
        await _db.collection('users').doc(targetUserId).set({
          'followers': FieldValue.arrayRemove([_userId])
        }, SetOptions(merge: true));
      } catch (e) {
        _following.add(targetUserId);
        notifyListeners();
      }
    } else {
      _following.add(targetUserId);
      notifyListeners();
      
      try {
        await _db.collection('users').doc(_userId).set({
          'following': FieldValue.arrayUnion([targetUserId])
        }, SetOptions(merge: true));
        await _db.collection('users').doc(targetUserId).set({
          'followers': FieldValue.arrayUnion([_userId])
        }, SetOptions(merge: true));
      } catch (e) {
        _following.remove(targetUserId);
        notifyListeners();
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
