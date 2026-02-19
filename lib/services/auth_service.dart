import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Hakikisha ume-install package hii
import 'package:flutter/foundation.dart';

class UsersPageResult {
  final List<Map<String, dynamic>> users;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const UsersPageResult({
    required this.users,
    required this.lastDocument,
    required this.hasMore,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  AuthService() {
    _firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // ================= UPDATE PROFILE PHOTO =================
  /// Upload profile photo for both web (bytes) and mobile (file path),
  /// then persist URL in Firebase Auth and Firestore.
  Future<String> updateProfilePhoto({
    String? filePath,
    Uint8List? fileBytes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in.");

    try {
      // Upload using unique filename to avoid stale/overwritten-reference issues.
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage
          .ref()
          .child('profile_pics')
          .child(user.uid)
          .child(fileName);
      TaskSnapshot snapshot;

      if (kIsWeb) {
        if (fileBytes == null) {
          throw Exception("Image bytes are required on web.");
        }
        snapshot = await ref.putData(
          fileBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        if (filePath == null || filePath.isEmpty) {
          throw Exception("Image path is required on mobile/desktop.");
        }
        final file = File(filePath);
        if (!file.existsSync()) {
          throw Exception("Selected image file does not exist.");
        }
        snapshot = await ref.putFile(file);
      }

      // Pata URL ya picha iliyopakiwa
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update Firebase Auth Profile
      await user.updatePhotoURL(downloadUrl);

      // Update Firestore User Document
      await _firestore.collection('users').doc(user.uid).set({
        'profilePic': downloadUrl,
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      debugPrint("Update Profile Photo Error: $e");
      rethrow;
    }
  }

  // ================= CHANGE PASSWORD =================
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    User? user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("No user logged in.");
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        throw 'The current password you entered is incorrect.';
      } else {
        throw e.message ?? 'An error occurred while changing password.';
      }
    } catch (e) {
      throw e.toString();
    }
  }

  // ================= DELETE ACCOUNT (WITH RE-AUTH) =================
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;

    debugPrint("Delete account - Current user: ${user?.email ?? 'null'}");
    debugPrint("Delete account - Current user ID: ${user?.uid ?? 'null'}");

    if (user == null || user.email == null) {
      throw Exception("Hakuna mtumiaji aliyeingia. Tafadhali ingia kwanza.");
    }

    try {
      // 1. Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint("Re-authentication successful");

      // 2. Try to clean up chats (this might fail due to permissions, but continue)
      try {
        final chatsSnapshot = await _firestore
            .collection('chats')
            .where('participants', arrayContains: user.uid)
            .get();

        debugPrint("Found ${chatsSnapshot.docs.length} chats to clean up");

        // Delete all messages in user's chats and update/remove chats
        for (var chatDoc in chatsSnapshot.docs) {
          final chatId = chatDoc.id;
          final data = chatDoc.data();
          final participants = List<String>.from(data['participants'] ?? []);

          // Delete all messages in this chat
          final messagesSnapshot = await _firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .get();

          final batch = _firestore.batch();
          for (var messageDoc in messagesSnapshot.docs) {
            batch.delete(messageDoc.reference);
          }

          // If chat has only one participant (this user), delete the chat doc
          // If it has two participants, remove this user from participants
          if (participants.length <= 1) {
            batch.delete(chatDoc.reference);
          } else {
            // Remove user from participants
            participants.remove(user.uid);
            batch.update(chatDoc.reference, {'participants': participants});
          }

          await batch.commit();
          debugPrint("Cleaned up chat: $chatId");
        }
      } catch (e) {
        debugPrint(
          "Failed to clean up chats (might be expected after auth deletion): $e",
        );
      }

      // 3. Try to delete user data from Firestore
      try {
        await _firestore.collection('users').doc(user.uid).delete();
        debugPrint("Deleted user document from Firestore");
      } catch (e) {
        debugPrint(
          "Failed to delete user document (might be expected after auth deletion): $e",
        );
      }

      // 4. Delete profile image (optional)
      try {
        await _storage.ref('profile_pics/${user.uid}.jpg').delete();
        debugPrint("Deleted profile image from Storage");
      } catch (e) {
        debugPrint("Profile image not found or already deleted: $e");
      }

      // 5. Delete Firebase Auth account
      await user.delete();
      debugPrint("Deleted Firebase Auth account");

      // 6. Sign out completely (though not necessary since user is deleted)
      await _auth.signOut();
      debugPrint("Signed out successfully");
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      rethrow;
    }
  }

  // ================= REGISTER =================
  Future<User?> registerWithEmail(
    String email,
    String password,
    String username,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'profilePic': null, // Inatengenezwa ikiwa empty
          'createdAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      debugPrint("Register Error: $e");
      rethrow;
    }
  }

  // ================= LOGIN =================
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await updateUserStatus(true);
      return result.user;
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await updateUserStatus(false);
    await _auth.signOut();
  }

  User? getCurrentUser() => _auth.currentUser;

  // ================= GET ALL USERS =================
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final snapshot = await _firestore.collection('users').limit(20).get();
    final currentUserId = _auth.currentUser?.uid;

    return snapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'username': data['username'] ?? 'Unknown',
        'email': data['email'] ?? '',
        'profilePic': data['profilePic'], // Tumeongeza hii
        'isOnline': data.containsKey('isOnline') ? data['isOnline'] : false,
      };
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    final currentUserId = _auth.currentUser?.uid;
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) {
            final data = doc.data();
            return {
              'uid': doc.id,
              'username': data['username'] ?? 'Unknown',
              'email': data['email'] ?? '',
              'profilePic': data['profilePic'],
              'isOnline': data['isOnline'] == true,
              'lastSeen': data['lastSeen'],
            };
          })
          .toList();

      users.sort((a, b) {
        return (a['username'] as String).toLowerCase().compareTo(
          (b['username'] as String).toLowerCase(),
        );
      });

      return users;
    });
  }

  Future<UsersPageResult> getUsersPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
  }) async {
    final currentUserId = _auth.currentUser?.uid;

    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .orderBy('username')
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;

    final users = docs.where((doc) => doc.id != currentUserId).map((doc) {
      final data = doc.data();
      return {
        'uid': doc.id,
        'username': data['username'] ?? 'Unknown',
        'email': data['email'] ?? '',
        'profilePic': data['profilePic'],
        'isOnline': data['isOnline'] == true,
        'lastSeen': data['lastSeen'],
      };
    }).toList();

    return UsersPageResult(
      users: users,
      lastDocument: docs.isNotEmpty ? docs.last : lastDocument,
      hasMore: docs.length == limit,
    );
  }

  // ================= CHAT ID =================
  String generateChatId(String otherUserId) {
    final currentUserId = _auth.currentUser?.uid ?? '';
    final ids = [currentUserId, otherUserId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // ================= SEND MESSAGE =================
  Future<void> sendMessage(
    String chatId,
    String message,
    String recipientId,
  ) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    await chatRef.collection('messages').add({
      'senderId': currentUserId,
      'recipientId': recipientId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sent',
    });

    await chatRef.set({
      'participants': [currentUserId, recipientId],
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
      'unreadCount': {recipientId: FieldValue.increment(1)},
    }, SetOptions(merge: true));
  }

  // ================= MARK AS DELIVERED/READ =================
  Future<void> markMessagesAsDelivered(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final snapshot = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('recipientId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'sent')
        .get();

    if (snapshot.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'status': 'delivered'});
    }
    await batch.commit();
  }

  Future<void> markMessagesAsRead(String chatId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final chatRef = _firestore.collection('chats').doc(chatId);
    final snapshot = await chatRef
        .collection('messages')
        .where('recipientId', isEqualTo: currentUserId)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();

    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    batch.set(chatRef, {
      'unreadCount': {currentUserId: 0},
    }, SetOptions(merge: true));
    await batch.commit();
  }

  // ================= STREAMS =================
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(40)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList()
              .reversed
              .toList(),
        );
  }
  Stream<List<Map<String, dynamic>>> getConversationsStream({
    int limit = 50,
  }) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception("User not logged in");

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .asyncMap((snapshot) async {
          final chatDocs = snapshot.docs;
          final otherUserIds = chatDocs
              .map((doc) {
                final data = doc.data();
                final participants = List<String>.from(
                  data['participants'] ?? [],
                );
                return participants.firstWhere(
                  (id) => id != currentUserId,
                  orElse: () => '',
                );
              })
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

          final usersById = await _getUsersByIds(otherUserIds);

          final conversations = chatDocs.map((doc) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
              (id) => id != currentUserId,
              orElse: () => '',
            );

            final userData = usersById[otherUserId] ?? const {};
            final unreadMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
            final unreadCount = (unreadMap[currentUserId] as num?)?.toInt() ?? 0;

            return {
              'chatId': doc.id,
              'userId': otherUserId,
              'username': userData['username'] ?? 'Unknown',
              'profilePic': userData['profilePic'],
              'isOnline': userData['isOnline'] == true,
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': data['lastMessageTime'],
              'unreadCount': unreadCount,
              'lastMessageSenderId': data['lastMessageSenderId'],
            };
          }).where((chat) => (chat['userId'] as String).isNotEmpty).toList();

          conversations.sort((a, b) {
            final timeA = a['lastMessageTime'] as Timestamp?;
            final timeB = b['lastMessageTime'] as Timestamp?;
            if (timeA == null && timeB == null) return 0;
            if (timeA == null) return 1;
            if (timeB == null) return -1;
            return timeB.compareTo(timeA);
          });

          if (conversations.length > limit) {
            return conversations.take(limit).toList();
          }

          return conversations;
        });
  }

  Future<Map<String, Map<String, dynamic>>> _getUsersByIds(
    List<String> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    const chunkSize = 10;
    final chunks = <List<String>>[];
    for (var i = 0; i < userIds.length; i += chunkSize) {
      final end = (i + chunkSize < userIds.length)
          ? i + chunkSize
          : userIds.length;
      chunks.add(userIds.sublist(i, end));
    }

    final futures = chunks
        .map(
          (chunk) => _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get(),
        )
        .toList();

    final snapshots = await Future.wait(futures);
    final result = <String, Map<String, dynamic>>{};

    for (final snapshot in snapshots) {
      for (final doc in snapshot.docs) {
        result[doc.id] = doc.data();
      }
    }

    return result;
  }
  // ================= USER PROFILE UPDATES =================
  Future<void> updateUsername(String newUsername) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;
    await _firestore.collection('users').doc(currentUserId).set({
      'username': newUsername,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }

  Future<void> updateUserStatus(bool isOnline) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserStatusStream(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
