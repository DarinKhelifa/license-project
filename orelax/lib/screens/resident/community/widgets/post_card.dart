import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../models/post_model.dart';
import '../../../../providers/social_provider.dart';
import '../post/post_details_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool isLiked;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLikedByCurrentUser;
  }

  @override
  Widget build(BuildContext context) {
    const Color darkGreen = Color(0xFF1A5C2A);
    const Color lightGreen = Color(0xFFE8F5E9);

    return Container(
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Avatar
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
                // Name and Time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
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
                // Menu
                PopupMenuButton(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('Report'),
                      onTap: () {},
                    ),
                    PopupMenuItem(
                      child: Text('Hide'),
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              widget.post.content,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ),

          // Images
          if (widget.post.imageUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildImageGallery(),
            ),

          // Attachments indicator
          if (widget.post.attachmentUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.post.attachmentUrls.length} attachment(s)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Reactions and stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Reaction stats
                Row(
                  children: [
                    Text(
                      '👍 ${widget.post.likes}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                // Comments and shares
                Row(
                  children: [
                    Text(
                      '${widget.post.comments} comments',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 8),
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

          // Divider
          Divider(height: 1, color: Colors.grey.shade200),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: 'Like',
                  color: isLiked ? Colors.red : Colors.grey.shade600,
                  onTap: () async {
                    setState(() => isLiked = !isLiked);
                    await context.read<SocialProvider>().likePost(widget.post.id);
                  },
                ),
                _buildActionButton(
                  icon: Icons.comment_outlined,
                  label: 'Comment',
                  color: Colors.grey.shade600,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PostDetailsScreen(post: widget.post),
                    ),
                  ),
                ),
                _buildActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  color: Colors.grey.shade600,
                  onTap: () => context.read<SocialProvider>().sharePost(widget.post.id),
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

    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          images[0],
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: double.infinity,
            height: 300,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade200,
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
