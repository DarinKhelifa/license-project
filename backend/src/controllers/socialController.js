const Post = require('../models/Post');
const Story = require('../models/Story');
const Comment = require('../models/Comment');
const User = require('../models/User');
const Chat = require('../models/Chat');
const Message = require('../models/Message');

// ============ POSTS ============

// Get all posts with pagination
exports.getPosts = async (req, res) => {
  try {
    const page = parseInt(req.query.page, 10) || 1;
    const limit = parseInt(req.query.limit, 10) || 10;
    const skip = (page - 1) * limit;

    const posts = await Post.find()
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean();

    // Get current user ID from auth middleware
    const userId = req.user?._id;

    // Add isLikedByCurrentUser field for each post
    const enrichedPosts = posts.map(post => ({
      ...post,
      isLikedByCurrentUser: userId ? post.likedBy.includes(userId) : false,
    }));

    const total = await Post.countDocuments();

    res.json({
      posts: enrichedPosts,
      pagination: {
        current: page,
        total: Math.ceil(total / limit),
        count: posts.length,
      },
    });
  } catch (error) {
    console.error('Error getting posts:', error);
    res.status(500).json({ error: error.message });
  }
};

// Create a new post
exports.createPost = async (req, res) => {
  try {
    const { content } = req.body;
    const userId = req.user._id;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Post content is required' });
    }

    // Get user info
    const user = await User.findById(userId).lean();

    const imageUrls = req.files
      ?.filter(f => f.fieldname === 'images')
      ?.map(f => `/uploads/${f.filename}`) || [];

    const attachmentUrls = req.files
      ?.filter(f => f.fieldname === 'attachments')
      ?.map(f => `/uploads/${f.filename}`) || [];

    const post = new Post({
      userId,
      userName: user?.name || 'Anonymous',
      userAvatar: user?.profileImage || '',
      content,
      imageUrls,
      attachmentUrls,
    });

    await post.save();

    res.status(201).json({ post });
  } catch (error) {
    console.error('Error creating post:', error);
    res.status(500).json({ error: error.message });
  }
};

// Delete a post
exports.deletePost = async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    // Check if user owns the post
    if (post.userId.toString() !== userId.toString()) {
      return res.status(403).json({ error: 'Not authorized to delete this post' });
    }

    // Delete associated comments
    await Comment.deleteMany({ postId });

    // Delete the post
    await Post.findByIdAndDelete(postId);

    res.json({ message: 'Post deleted successfully' });
  } catch (error) {
    console.error('Error deleting post:', error);
    res.status(500).json({ error: error.message });
  }
};

// Like a post
exports.likePost = async (req, res) => {
  try {
    const { postId } = req.params;
    const userId = req.user._id;

    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    const likedIndex = post.likedBy.indexOf(userId);

    if (likedIndex > -1) {
      // Unlike the post
      post.likedBy.splice(likedIndex, 1);
      post.likes = Math.max(0, post.likes - 1);
    } else {
      // Like the post
      post.likedBy.push(userId);
      post.likes += 1;
    }

    await post.save();

    const postObj = post.toObject();
    postObj.isLikedByCurrentUser = post.likedBy.includes(userId);

    res.json({ post: postObj });
  } catch (error) {
    console.error('Error liking post:', error);
    res.status(500).json({ error: error.message });
  }
};

// Add reaction to a post
exports.addReaction = async (req, res) => {
  try {
    const { postId } = req.params;
    const { emoji } = req.body;
    const userId = req.user._id;

    if (!emoji) {
      return res.status(400).json({ error: 'Emoji is required' });
    }

    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    // Check if user already reacted with this emoji
    const reactionIndex = post.reactions.findIndex(
      r => r.userId.toString() === userId.toString() && r.emoji === emoji
    );

    if (reactionIndex > -1) {
      // Remove reaction
      post.reactions.splice(reactionIndex, 1);
    } else {
      // Add reaction
      post.reactions.push({ userId, emoji });
    }

    await post.save();

    const postObj = post.toObject();
    postObj.isLikedByCurrentUser = post.likedBy.includes(userId);

    res.json({ post: postObj });
  } catch (error) {
    console.error('Error adding reaction:', error);
    res.status(500).json({ error: error.message });
  }
};

// Share a post
exports.sharePost = async (req, res) => {
  try {
    const { postId } = req.params;

    const post = await Post.findById(postId);

    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    post.shares += 1;
    await post.save();

    const postObj = post.toObject();
    postObj.isLikedByCurrentUser = req.user ? post.likedBy.includes(req.user._id) : false;

    res.json({ post: postObj });
  } catch (error) {
    console.error('Error sharing post:', error);
    res.status(500).json({ error: error.message });
  }
};

// Share a post with a specific user (send via chat)
exports.sharePostWithUser = async (req, res) => {
  try {
    const { postId } = req.params;
    const { recipientUserId } = req.body;
    const senderId = req.user._id.toString();

    // Validate recipient user exists
    const recipientUser = await User.findById(recipientUserId);
    if (!recipientUser) {
      return res.status(404).json({ error: 'Recipient user not found' });
    }

    // Validate post exists
    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    // Prevent sharing to self
    if (senderId === recipientUserId) {
      return res.status(400).json({ error: 'Cannot share with yourself' });
    }

    // Find or create chat
    let chat = await Chat.findOne({
      participants: { $all: [senderId, recipientUserId] },
      type: 'private'
    });

    if (!chat) {
      const senderUser = await User.findById(senderId);
      chat = new Chat({
        participants: [senderId, recipientUserId],
        participantNames: [senderUser.name, recipientUser.name],
        participantAvatars: [senderUser.profileImage || '', recipientUser.profileImage || ''],
        type: 'private',
      });
      await chat.save();
    }

    // Create message with post information
    const postText = `🔗 Shared Post: ${post.content.substring(0, 100)}${post.content.length > 100 ? '...' : ''}`;
    const message = new Message({
      chatId: chat._id.toString(),
      senderId: senderId,
      senderName: req.user.name,
      text: postText,
      type: 'text',
    });
    await message.save();

    // Update chat's last message
    chat.lastMessage = postText;
    chat.lastMessageTime = new Date();
    chat.lastMessageSenderId = senderId;
    chat.unreadCount = chat.unreadCount || {};
    chat.unreadCount[recipientUserId] = (chat.unreadCount[recipientUserId] || 0) + 1;
    await chat.save();

    // Increment post shares
    post.shares += 1;
    await post.save();

    res.json({
      message: 'Post shared successfully',
      chatId: chat._id,
      message: message
    });
  } catch (error) {
    console.error('Error sharing post with user:', error);
    res.status(500).json({ error: error.message });
  }
};

// ============ COMMENTS ============

// Get comments for a post
exports.getComments = async (req, res) => {
  try {
    const { postId } = req.params;

    const comments = await Comment.find({ postId })
      .sort({ createdAt: 1 })
      .lean();

    res.json({ comments });
  } catch (error) {
    console.error('Error getting comments:', error);
    res.status(500).json({ error: error.message });
  }
};

// Add a comment to a post
exports.addComment = async (req, res) => {
  try {
    const { postId } = req.params;
    const { content } = req.body;
    const userId = req.user._id;

    if (!content || content.trim().length === 0) {
      return res.status(400).json({ error: 'Comment content is required' });
    }

    // Verify post exists
    const post = await Post.findById(postId);
    if (!post) {
      return res.status(404).json({ error: 'Post not found' });
    }

    // Get user info
    const user = await User.findById(userId).lean();

    const comment = new Comment({
      postId,
      userId,
      userName: user?.name || 'Anonymous',
      userAvatar: user?.profileImage || '',
      content,
    });

    await comment.save();

    // Update post comment count
    post.comments += 1;
    await post.save();

    res.status(201).json({ comment });
  } catch (error) {
    console.error('Error adding comment:', error);
    res.status(500).json({ error: error.message });
  }
};

// Delete a comment
exports.deleteComment = async (req, res) => {
  try {
    const { postId, commentId } = req.params;
    const userId = req.user._id;

    const comment = await Comment.findById(commentId);

    if (!comment) {
      return res.status(404).json({ error: 'Comment not found' });
    }

    // Check if user owns the comment
    if (comment.userId.toString() !== userId.toString()) {
      return res.status(403).json({ error: 'Not authorized to delete this comment' });
    }

    // Update post comment count
    const post = await Post.findById(postId);
    if (post) {
      post.comments = Math.max(0, post.comments - 1);
      await post.save();
    }

    await Comment.findByIdAndDelete(commentId);

    res.json({ message: 'Comment deleted successfully' });
  } catch (error) {
    console.error('Error deleting comment:', error);
    res.status(500).json({ error: error.message });
  }
};

// ============ STORIES ============

// Get all active stories
exports.getStories = async (req, res) => {
  try {
    const userId = req.user?._id;

    // Find stories that haven't expired
    const stories = await Story.find({
      expiresAt: { $gt: new Date() },
    })
      .sort({ createdAt: -1 })
      .lean();

    // Mark if viewed by current user
    const enrichedStories = stories.map(story => ({
      ...story,
      viewed: userId ? story.viewedBy.includes(userId) : false,
    }));

    res.json({ stories: enrichedStories });
  } catch (error) {
    console.error('Error getting stories:', error);
    res.status(500).json({ error: error.message });
  }
};

// Create a new story
exports.createStory = async (req, res) => {
  try {
    const userId = req.user._id;

    if (!req.file) {
      return res.status(400).json({ error: 'Story image is required' });
    }

    // Get user info
    const user = await User.findById(userId).lean();

    const story = new Story({
      userId,
      userName: user?.name || 'Anonymous',
      userAvatar: user?.profileImage || '',
      imageUrl: `/uploads/${req.file.filename}`,
    });

    await story.save();

    const storyObj = story.toObject();
    storyObj.viewed = false;

    res.status(201).json({ story: storyObj });
  } catch (error) {
    console.error('Error creating story:', error);
    res.status(500).json({ error: error.message });
  }
};

// Mark story as viewed
exports.viewStory = async (req, res) => {
  try {
    const { storyId } = req.params;
    const userId = req.user._id;

    const story = await Story.findById(storyId);

    if (!story) {
      return res.status(404).json({ error: 'Story not found' });
    }

    // Add user to viewedBy if not already there
    if (!story.viewedBy.includes(userId)) {
      story.viewedBy.push(userId);
      await story.save();
    }

    res.json({ story });
  } catch (error) {
    console.error('Error viewing story:', error);
    res.status(500).json({ error: error.message });
  }
};

// Add reaction to story
exports.addStoryReaction = async (req, res) => {
  try {
    const { storyId } = req.params;
    const { emoji } = req.body;
    const userId = req.user._id;

    if (!emoji) {
      return res.status(400).json({ error: 'Emoji is required' });
    }

    const story = await Story.findById(storyId);

    if (!story) {
      return res.status(404).json({ error: 'Story not found' });
    }

    // Check if user already reacted with this emoji
    const reactionIndex = story.reactions.findIndex(
      r => r.userId.toString() === userId.toString() && r.emoji === emoji
    );

    if (reactionIndex > -1) {
      // Remove reaction
      story.reactions.splice(reactionIndex, 1);
    } else {
      // Add reaction
      story.reactions.push({ userId, emoji });
    }

    await story.save();

    res.json({ story });
  } catch (error) {
    console.error('Error adding story reaction:', error);
    res.status(500).json({ error: error.message });
  }
};
