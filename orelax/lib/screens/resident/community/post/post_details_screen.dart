import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:orelax/widgets/custom_bottom_nav_bar.dart';
import '../../../../models/post_model.dart';
import '../../../../providers/social_provider.dart';
import '../../../../models/comment_model.dart';

class PostDetailsScreen extends StatefulWidget {
  final Post post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLiking = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    await context.read<SocialProvider>().fetchComments(widget.post.id);
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;

    final success = await context.read<SocialProvider>().addComment(
          widget.post.id,
          _commentController.text,
        );

    if (success) {
      _commentController.clear();
      _loadComments();
      _showSnackBar('Comment posted!');
    } else {
      _showSnackBar('Failed to post comment', isError: true);
    }
  }

  Future<void> _likePost() async {
    setState(() => _isLiking = true);
    final success =
        await context.read<SocialProvider>().likePost(widget.post.id);
    setState(() => _isLiking = false);

    if (success) {
      _showSnackBar(widget.post.isLikedByCurrentUser ? 'Unliked' : 'Liked!');
    } else {
      _showSnackBar('Failed to like post', isError: true);
    }
  }

  Future<void> _sharePost() async {
    setState(() => _isSharing = true);
    final success =
        await context.read<SocialProvider>().sharePost(widget.post.id);
    setState(() => _isSharing = false);

    if (success) {
      _showSnackBar('Post shared!');
    } else {
      _showSnackBar('Failed to share post', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF1A5C2A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);
    const Color lightGreen = Color(0xFFE8F5E9);

    return Scaffold(
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        scrolledUnderElevation: 0,
        title: Text(
          'Post',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: darkGreen,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Post Details
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Post Card
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: lightGreen,
                              backgroundImage: widget.post.userAvatar.isNotEmpty
                                  ? NetworkImage(widget.post.userAvatar)
                                  : null,
                              child: widget.post.userAvatar.isEmpty
                                  ? const Icon(Icons.person, color: darkGreen)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.post.userName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    widget.post.formattedDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Content
                        Text(
                          widget.post.content,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.grey.shade800,
                          ),
                        ),

                        // Images
                        if (widget.post.imageUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildImageGallery(),
                          ),

                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200),

                        // Stats and Actions
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.favorite,
                                      size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.post.likes}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${widget.post.comments} comments',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${widget.post.shares} shares',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Divider(color: Colors.grey.shade200),

                        // Action Buttons
                        Row(
                          children: [
                            _buildActionButton(
                              icon: widget.post.isLikedByCurrentUser
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              label: 'Like',
                              color: widget.post.isLikedByCurrentUser
                                  ? Colors.red
                                  : Colors.grey.shade600,
                              onTap: _isLiking ? null : _likePost,
                              isLoading: _isLiking,
                            ),
                            _buildActionButton(
                              icon: Icons.comment_outlined,
                              label: 'Comment',
                              color: Colors.grey.shade600,
                              onTap: () => _focusCommentField(),
                            ),
                            _buildActionButton(
                              icon: Icons.share_outlined,
                              label: 'Share',
                              color: Colors.grey.shade600,
                              onTap: _isSharing ? null : _sharePost,
                              isLoading: _isSharing,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Comments Section
                  Consumer<SocialProvider>(
                    builder: (context, socialProvider, _) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: FutureBuilder(
                          future: socialProvider.getComments(widget.post.id),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: darkGreen,
                                ),
                              );
                            }

                            final commentsList = snapshot.data ?? [];

                            if (commentsList.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    Icon(Icons.comment_outlined,
                                        size: 40, color: Colors.grey.shade300),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No comments yet. Be the first!',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: commentsList.length,
                              itemBuilder: (context, index) {
                                final comment = commentsList[index];
                                return _buildCommentItem(
                                  comment,
                                  darkGreen,
                                  lightGreen,
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // Comment Input
          Container(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _postComment(),
                    decoration: InputDecoration(
                      hintText: 'Write a comment...',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(
                          color: Color(0xFF1A5C2A),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _postComment,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C2A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A5C2A).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    final images = widget.post.imageUrls;

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          images[0],
          width: double.infinity,
          height: 250,
          fit: BoxFit.cover,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(
    Comment comment,
    Color darkGreen,
    Color lightGreen,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: lightGreen,
            backgroundImage: comment.userAvatar.isNotEmpty
                ? NetworkImage(comment.userAvatar)
                : null,
            child: comment.userAvatar.isEmpty
                ? const Icon(Icons.person, color: Color(0xFF1A5C2A), size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 6),
                  child: Text(
                    comment.formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap != null ? 1.0 : 0.6,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  )
                else
                  Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _focusCommentField() {
    FocusScope.of(context).requestFocus(FocusNode());
    // Could scroll to comment section if needed
  }
}
