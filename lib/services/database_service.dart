import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Create user document
  Future<void> createUserDocument(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      print('Error creating user document: $e');
      throw e;
    }
  }

  // Create a new post
  Future<void> createPost(
    String userId,
    String userName,
    String text,
    File? imageFile,
  ) async {
    try {
      String postId = _firestore.collection('posts').doc().id;
      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, 'posts/$postId');
      }

      PostModel post = PostModel(
        postId: postId,
        userId: userId,
        userName: userName,
        text: text,
        imageUrl: imageUrl,
        likes: [],
        commentCount: 0,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('posts').doc(postId).set(post.toMap());
    } catch (e) {
      print('Error creating post: $e');
      throw e;
    }
  }

  // Get all posts stream
  Stream<List<PostModel>> getAllPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Get user posts
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          var posts = snapshot.docs
              .map((doc) => PostModel.fromMap(doc.data()))
              .toList();
          // Sort in memory instead of using Firestore orderBy to avoid composite index
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return posts;
        });
  }

  // Toggle like on post
  Future<void> toggleLike(String postId, String userId) async {
    try {
      DocumentReference postRef = _firestore.collection('posts').doc(postId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(postRef);

        if (snapshot.exists) {
          List<String> likes = List<String>.from(snapshot.get('likes') ?? []);

          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
          }

          transaction.update(postRef, {'likes': likes});
        }
      });
    } catch (e) {
      print('Error toggling like: $e');
      throw e;
    }
  }

  // Add comment to post
  Future<void> addComment(
    String postId,
    String userId,
    String userName,
    String text,
  ) async {
    try {
      String commentId = _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc()
          .id;

      CommentModel comment = CommentModel(
        commentId: commentId,
        postId: postId,
        userId: userId,
        userName: userName,
        text: text,
        createdAt: DateTime.now(),
      );

      // Add comment to subcollection
      await _firestore
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .set(comment.toMap());

      // Update comment count
      await _firestore.collection('posts').doc(postId).update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error adding comment: $e');
      throw e;
    }
  }

  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CommentModel.fromMap(doc.data()))
              .toList(),
        );
  }

  // Search posts
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      // Search in post text
      QuerySnapshot textResults = await _firestore
          .collection('posts')
          .where('text', isGreaterThanOrEqualTo: query)
          .where('text', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Search in user names
      QuerySnapshot userResults = await _firestore
          .collection('posts')
          .where('userName', isGreaterThanOrEqualTo: query)
          .where('userName', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      Set<PostModel> allResults = {};

      for (var doc in textResults.docs) {
        allResults.add(PostModel.fromMap(doc.data() as Map<String, dynamic>));
      }

      for (var doc in userResults.docs) {
        allResults.add(PostModel.fromMap(doc.data() as Map<String, dynamic>));
      }

      return allResults.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      print('Error searching posts: $e');
      return [];
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile, String path) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      throw e;
    }
  }

  // Upload profile picture
  Future<String> uploadProfilePicture(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');

    return await _uploadImage(imageFile, 'profile_pictures/${user.uid}');
  }

  // Update user profile
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      throw e;
    }
  }
}
