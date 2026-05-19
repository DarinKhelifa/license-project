const express = require('express');
const router = express.Router();
const socialController = require('../controllers/socialController');
const { protect: auth } = require('../middleware/auth');
const upload = require('../middleware/upload');

// ============ POSTS ============

// Get all posts (public, but auth optional)
router.get('/posts', socialController.getPosts);

// Create a new post (auth required, file upload)
router.post(
  '/posts',
  auth,
  upload.array('images', 10), // Max 10 images
  socialController.createPost
);

// Delete a post (auth required)
router.delete('/posts/:postId', auth, socialController.deletePost);

// Like a post (auth required)
router.post('/posts/:postId/like', auth, socialController.likePost);

// Add reaction to a post (auth required)
router.post('/posts/:postId/react', auth, socialController.addReaction);

// Share a post (auth required)
router.post('/posts/:postId/share', auth, socialController.sharePost);

// Share a post with a specific user (auth required)
router.post('/posts/:postId/share-with-user', auth, socialController.sharePostWithUser);

// ============ COMMENTS ============

// Get all comments for a post (public)
router.get('/posts/:postId/comments', socialController.getComments);

// Add a comment to a post (auth required)
router.post('/posts/:postId/comments', auth, socialController.addComment);

// Delete a comment (auth required)
router.delete(
  '/posts/:postId/comments/:commentId',
  auth,
  socialController.deleteComment
);

// ============ STORIES ============

// Get all active stories (public, but auth optional)
router.get('/stories', socialController.getStories);

// Create a new story (auth required, file upload)
router.post(
  '/stories',
  auth,
  upload.single('image'),
  socialController.createStory
);

// Mark story as viewed (auth required)
router.post('/stories/:storyId/view', auth, socialController.viewStory);

// Add reaction to story (auth required)
router.post('/stories/:storyId/react', auth, socialController.addStoryReaction);

module.exports = router;
