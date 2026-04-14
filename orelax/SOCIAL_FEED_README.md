# Community Feed - Mini Social App

## Overview
A modern, feature-rich community feed system for ORELAX residents to share stories, posts, comments, and engage with each other through reactions.

## Features

### 1. **Stories** (24-hour expiring content)
- View story carousel on the feed
- Create stories with camera or gallery
- Stories expire after 24 hours automatically
- Visual indicators for viewed/unviewed stories
- Full-screen story viewing with:
  - Navigation (previous/next story)
  - Reaction emojis
  - Reply functionality
  - Share options

### 2. **Posts**
- Create posts with text content
- Upload multiple images with gallery view
- Add file attachments (documents, PDFs, etc.)
- Rich timestamp formatting (now, 5m ago, 2h ago, etc.)
- Like/reaction system with emoji support
- Comment count, share count tracking
- Delete own posts
- Report/hide unhelpful posts

### 3. **Comments**
- Add comments to posts
- View all comments in chronological order
- User names, avatars, and timestamps
- Like comments (future enhancement)
- Delete own comments

### 4. **Reactions**
- Like posts with heart icon
- Add emoji reactions (👍, ❤️, 😂, 😮, 😢, 🔥)
- Visual feedback with color changes
- Reaction counters

### 5. **Modern UI/UX**
- Green color scheme matching the app (Dark Green: #1A5C2A)
- Smooth animations and transitions
- Responsive design
- Loading states
- Empty states
- Error handling with snackbars
- Gesture-based interactions

## File Structure

```
lib/
├── models/
│   ├── post_model.dart          # Post data model with helpers
│   ├── story_model.dart         # Story data model with expiry logic
│   └── comment_model.dart       # Comment data model
├── services/
│   └── social_api_service.dart  # API calls for social operations
├── providers/
│   └── social_provider.dart     # State management with ChangeNotifier
└── screens/
    └── resident/
        └── community/
            ├── community_feed_screen.dart       # Main feed screen
            ├── create_post_screen.dart          # Post creation
            ├── widgets/
            │   ├── story_carousel.dart          # Story carousel widget
            │   └── post_card.dart               # Post display widget
            ├── story/
            │   ├── create_story_screen.dart     # Story creation
            │   └── story_view_screen.dart       # Fullscreen story viewer
            └── post/
                └── post_details_screen.dart     # Post with comments
```

## API Endpoints Required

The app expects these backend endpoints:

```
POST   /api/social/posts              # Create post
GET    /api/social/posts?page=1       # Get paginated posts
DELETE /api/social/posts/:postId      # Delete post
POST   /api/social/posts/:postId/like # Like post
POST   /api/social/posts/:postId/react # Add emoji reaction
POST   /api/social/posts/:postId/share # Share post

GET    /api/social/posts/:postId/comments      # Get comments
POST   /api/social/posts/:postId/comments      # Add comment
DELETE /api/social/posts/:postId/comments/:commentId # Delete comment

GET    /api/social/stories            # Get all stories
POST   /api/social/stories            # Create story
```

## How to Use

### Accessing the Community Feed
Navigate to `/feed` route or tap "Community Feed" from the home dashboard.

### Creating a Post
1. Tap "What's on your mind?" input field
2. Write your message
3. Add images via the Photo/Video button
4. Add attachments via the Attachment button
5. Tap "Post" to share

### Creating a Story
1. Tap "Add Story" in the story carousel
2. Choose Camera or Gallery
3. Preview and adjust the image
4. Tap "Post" to share (expires in 24 hours)

### Viewing Stories
1. Tap any story in the carousel to view fullscreen
2. Tap left side to go to previous story
3. Tap right side to go to next story
4. Use bottom actions to react, reply, or share

### Interacting with Posts
- **Like**: Tap heart icon (turns red when liked)
- **Comment**: Tap comment icon to view/add comments
- **Share**: Tap share icon to increment share count
- **React**: Click reaction emojis (future enhancement)

### Viewing Comments
1. Tap the comment button on a post
2. View all comments in chronological order
3. Type comment in the input field at bottom
4. Tap send (paper plane icon) to post comment

## Customization Guide

### Colors
Update the dark green color throughout:
```dart
const Color darkGreen = Color(0xFF1A5C2A);
const Color lightGreen = Color(0xFFE8F5E9);
```

### Image Quality
Modify image compression in `create_post_screen.dart` and `create_story_screen.dart`:
```dart
imageQuality: 85,  // Adjust 0-100
```

### Story Expiry Duration
In `story_model.dart`:
```dart
Duration(hours: 24)  // Change to desired duration
```

### Post Pagination
In `social_api_service.dart`:
```dart
'$baseUrl/social/posts?page=$page&limit=10'  // Change limit
```

## Dependencies Required

Add to `pubspec.yaml`:
```yaml
dependencies:
  google_fonts: ^6.0.0
  image_picker: ^1.0.0
  http: ^1.1.0
  http_parser: ^4.0.2
  shared_preferences: ^2.2.0
  intl: ^0.19.0
```

## Backend Integration

Your Express.js backend needs to handle these endpoints. Example structure:

```javascript
// Social routes
router.get('/posts', authMiddleware, getPosts);
router.post('/posts', authMiddleware, uploadMiddleware, createPost);
router.delete('/posts/:postId', authMiddleware, deletePost);
router.post('/posts/:postId/like', authMiddleware, likePost);
router.post('/posts/:postId/react', authMiddleware, addReaction);
router.post('/posts/:postId/share', authMiddleware, sharePost);

// Comments
router.get('/posts/:postId/comments', getComments);
router.post('/posts/:postId/comments', authMiddleware, addComment);
router.delete('/posts/:postId/comments/:commentId', authMiddleware, deleteComment);

// Stories
router.get('/stories', getStories);
router.post('/stories', authMiddleware, uploadMiddleware, createStory);
```

## Future Enhancements

1. **Emoji Picker**: Full emoji picker for reactions
2. **Text Editing**: Rich text formatting for posts
3. **Stickers & Filters**: For story creation
4. **Mentions & Tags**: @mention residents and #hashtags
5. **Notifications**: Alert users of likes/comments
6. **Search & Filters**: Find posts and stories by keyword
7. **Bookmarks**: Save favorite posts
8. **Admin Controls**: Moderate inappropriate content
9. **Real-time Updates**: WebSocket for live feed
10. **Sharing to Social Media**: Share externally
11. **Video Support**: Record and share videos
12. **Polls**: Create community polls

## Troubleshooting

### Posts not loading?
- Ensure backend endpoint is accessible
- Check network/WiFi connection
- Verify auth token is valid

### Images not uploading?
- Check file size limits
- Ensure image_picker is properly initialized
- Verify storage permissions

### Styling issues?
- Make sure google_fonts is imported
- Check color constants are correctly defined
- Verify font files are available

## Performance Tips

- Lazy load images with caching
- Paginate posts (10 per page by default)
- Debounce API calls
- Cache user avatars
- Use image compression for uploads

## Security Considerations

- Validate image file types on backend
- Set file size limits (e.g., 5MB for images, 10MB for attachments)
- Sanitize user input to prevent XSS
- Implement rate limiting for post/comment creation
- Add authentication checks on all endpoints
- Validate reactions are from actual users

---

**Created**: April 14, 2026
**Status**: Ready for integration with backend
