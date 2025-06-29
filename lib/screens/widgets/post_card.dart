import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/post_model.dart';
import '../../models/user_model.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../comments_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUserId;

  const PostCard({super.key, required this.post, required this.currentUserId});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final DatabaseService _databaseService = DatabaseService();
  final AuthService _authService = AuthService();

  Future<void> _toggleLike() async {
    try {
      await _databaseService.toggleLike(
        widget.post.postId,
        widget.currentUserId,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePost() async {
    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _databaseService.deletePost(widget.post.postId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildImageWidget(String imageData) {
    try {
      // Check if it's a base64 string (doesn't start with http)
      if (!imageData.startsWith('http')) {
        // Handle base64 image
        String base64String = imageData;
        if (imageData.contains(',')) {
          base64String = imageData.split(',')[1];
        }
        return Image.memory(
          base64Decode(base64String),
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error)),
          ),
        );
      } else {
        // Handle network URL (fallback for existing posts)
        return Image.network(
          imageData,
          width: double.infinity,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 200,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(child: Icon(Icons.error)),
          ),
        );
      }
    } catch (e) {
      return Container(
        height: 200,
        color: Colors.grey[300],
        child: const Center(child: Icon(Icons.error)),
      );
    }
  }

  Widget _buildUserAvatar(String userId, String userName) {
    return FutureBuilder<UserModel?>(
      future: _authService.getUserData(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: 20,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }

        final user = snapshot.data;
        if (user?.profilePicture == null) {
          return CircleAvatar(
            radius: 20,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }

        try {
          final imageData = user!.profilePicture!;

          // Check if it's a base64 string (doesn't start with http)
          if (!imageData.startsWith('http')) {
            // Handle base64 image
            String base64String = imageData;
            if (imageData.contains(',')) {
              base64String = imageData.split(',')[1];
            }
            return CircleAvatar(
              radius: 20,
              backgroundImage: MemoryImage(base64Decode(base64String)),
              onBackgroundImageError: (_, __) {},
              child: null,
            );
          } else {
            // Handle network URL (fallback for existing images)
            return CircleAvatar(
              radius: 20,
              backgroundImage: NetworkImage(imageData),
              onBackgroundImageError: (_, __) {},
              child: null,
            );
          }
        } catch (e) {
          return CircleAvatar(
            radius: 20,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = widget.post.likes.contains(widget.currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                _buildUserAvatar(widget.post.userId, widget.post.userName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getTimeAgo(widget.post.createdAt),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Show delete option for own posts
                if (widget.post.userId == widget.currentUserId)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePost();
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete Post',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                    icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Post Text
            Text(widget.post.text, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            // Post Image
            if (widget.post.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildImageWidget(widget.post.imageUrl!),
              ),
              const SizedBox(height: 12),
            ],
            // Like and Comment counts
            Row(
              children: [
                if (widget.post.likes.isNotEmpty) ...[
                  Icon(Icons.favorite, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.likes.length}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
                const Spacer(),
                if (widget.post.commentCount > 0) ...[
                  Text(
                    '${widget.post.commentCount} comments',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const Divider(),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _toggleLike,
                    icon: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                    ),
                    label: Text(
                      'Like',
                      style: TextStyle(
                        color: isLiked ? Colors.red : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommentsScreen(
                            post: widget.post,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.comment_outlined, color: Colors.grey),
                    label: Text(
                      'Comment',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
