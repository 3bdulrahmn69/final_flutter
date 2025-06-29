import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const CreatePostPage({
    Key? key,
    required this.toggleTheme,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _textController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();
  String? _selectedImageBase64;
  bool _isLoading = false;
  String? _userName;
  String? _userProfilePicture;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (mounted) {
          setState(() {
            _userName =
                userData?.fullName ?? user.displayName ?? user.email ?? 'User';
            _userProfilePicture = userData?.profilePicture;
          });
        }
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _selectImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Reduced quality for smaller file size
      maxWidth: 800, // Reduced max width
      maxHeight: 800, // Reduced max height
    );

    if (pickedFile != null) {
      try {
        // Convert image to base64
        final bytes = await pickedFile.readAsBytes();

        // Check file size before conversion (limit to 2MB)
        if (bytes.length > 2 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Please select a smaller image.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final base64String = base64Encode(bytes);

        setState(() {
          _selectedImageBase64 = base64String;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createPost() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text for your post'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get the actual user data to use the full name instead of email
      final userData = await _authService.getUserData(user.uid);
      final userName =
          userData?.fullName ?? user.displayName ?? user.email ?? 'Anonymous';

      await _databaseService.createPost(
        user.uid,
        userName,
        _textController.text.trim(),
        _selectedImageBase64,
      );

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildUserAvatar() {
    if (_userProfilePicture == null) {
      return CircleAvatar(
        backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
            ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
            : null,
        child: FirebaseAuth.instance.currentUser?.photoURL == null
            ? const Icon(Icons.person)
            : null,
      );
    }

    try {
      // Check if it's a base64 string (doesn't start with http)
      if (!_userProfilePicture!.startsWith('http')) {
        // Handle base64 image
        String base64String = _userProfilePicture!;
        if (_userProfilePicture!.contains(',')) {
          base64String = _userProfilePicture!.split(',')[1];
        }
        return CircleAvatar(
          backgroundImage: MemoryImage(base64Decode(base64String)),
          onBackgroundImageError: (_, __) {},
          child: null,
        );
      } else {
        // Handle network URL (fallback for existing images)
        return CircleAvatar(
          backgroundImage: NetworkImage(_userProfilePicture!),
          onBackgroundImageError: (_, __) {},
          child: null,
        );
      }
    } catch (e) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Post')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User info section
            Row(
              children: [
                _buildUserAvatar(),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName ?? 'Loading...',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Public',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Text input area
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                style: const TextStyle(fontSize: 18),
              ),
            ),

            // Selected image preview
            if (_selectedImageBase64 != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(base64Decode(_selectedImageBase64!)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImageBase64 = null;
                        });
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectImage,
                    icon: const Icon(Icons.photo_library, color: Colors.green),
                    label: const Text(
                      'Add Photo',
                      style: TextStyle(color: Colors.green),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Post button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Share Post',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
