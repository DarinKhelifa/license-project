# Social Feed Backend Implementation Guide

## Overview
Complete backend implementation for the community feed feature with database models, API routes, controllers, and middleware.

## Files Structure

```
backend/
├── src/
│   ├── models/
│   │   ├── Post.js          # Post schema with images, attachments, reactions
│   │   ├── Story.js         # Story schema with 24-hour expiry (TTL index)
│   │   └── Comment.js       # Comment schema linked to posts
│   ├── controllers/
│   │   └── socialController.js  # All business logic
│   ├── routes/
│   │   └── socialRoutes.js      # API endpoint definitions
│   └── middleware/
│       └── upload.js            # Multer file upload configuration
├── server.js               # Updated with social routes
└── package.json           # Already has multer dependency
```

## Database Models

### Post Model
```javascript
{
  userId: ObjectId,              // Reference to User
  userName: String,              // User's name for quick access
  userAvatar: String,            // Profile image URL
  content: String,               // Post text (max 5000 chars)
  imageUrls: [String],           // Array of image URLs
  attachmentUrls: [String],      // Array of attachment URLs
  likes: Number,                 // Like count
  likedBy: [ObjectId],           // Array of user IDs who liked
  comments: Number,              // Comment count
  shares: Number,                // Share count
  reactions: [{                  // Emoji reactions
    userId: ObjectId,
    emoji: String
  }],
  createdAt: Date,
  updatedAt: Date
}
```

### Story Model
```javascript
{
  userId: ObjectId,              // Reference to User
  userName: String,              // User's name
  userAvatar: String,            // Profile image URL
  imageUrl: String,              // Story image URL
  viewedBy: [ObjectId],          // Users who viewed story
  reactions: [{                  // Emoji reactions
    userId: ObjectId,
    emoji: String
  }],
  createdAt: Date,
  expiresAt: Date                // Auto-deletes after 24 hours via TTL index
}
```

### Comment Model
```javascript
{
  postId: ObjectId,              // Reference to Post
  userId: ObjectId,              // Reference to User
  userName: String,              // User's name
  userAvatar: String,            // Profile image URL
  content: String,               // Comment text (max 1000 chars)
  likes: Number,                 // Like count
  likedBy: [ObjectId],           // Users who liked comment
  createdAt: Date,
  updatedAt: Date
}
```

## API Endpoints

### Posts

#### GET /api/social/posts
Get paginated posts feed.

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Posts per page (default: 10)

**Response:**
```json
{
  "posts": [
    {
      "_id": "...",
      "userId": "...",
      "userName": "John Doe",
      "userAvatar": "/uploads/avatar.jpg",
      "content": "Great day at ORELAX!",
      "imageUrls": ["/uploads/img1.jpg"],
      "attachmentUrls": [],
      "likes": 5,
      "isLikedByCurrentUser": false,
      "comments": 2,
      "shares": 1,
      "reactions": [],
      "createdAt": "2026-04-14T10:30:00Z"
    }
  ],
  "pagination": {
    "current": 1,
    "total": 5,
    "count": 10
  }
}
```

#### POST /api/social/posts
Create a new post (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `content`: Post text (required)
- `images`: Multiple image files (optional, max 10)
- `attachments`: Multiple document files (optional)

**Response:**
```json
{
  "post": {
    "_id": "...",
    "userId": "...",
    ...
  }
}
```

#### DELETE /api/social/posts/:postId
Delete a post (requires authentication, user must own post).

**Response:**
```json
{
  "message": "Post deleted successfully"
}
```

#### POST /api/social/posts/:postId/like
Like/unlike a post (requires authentication).

**Response:**
```json
{
  "post": { ... }
}
```

#### POST /api/social/posts/:postId/react
Add emoji reaction to post (requires authentication).

**Body:**
```json
{
  "emoji": "👍"
}
```

**Response:**
```json
{
  "post": { ... }
}
```

#### POST /api/social/posts/:postId/share
Share a post (increments share count).

**Response:**
```json
{
  "post": { ... }
}
```

### Comments

#### GET /api/social/posts/:postId/comments
Get all comments for a post.

**Response:**
```json
{
  "comments": [
    {
      "_id": "...",
      "postId": "...",
      "userId": "...",
      "userName": "Jane Doe",
      "userAvatar": "/uploads/avatar2.jpg",
      "content": "Thanks for sharing!",
      "likes": 1,
      "createdAt": "2026-04-14T10:35:00Z"
    }
  ]
}
```

#### POST /api/social/posts/:postId/comments
Add comment to post (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
```

**Body:**
```json
{
  "content": "Great post!"
}
```

**Response:**
```json
{
  "comment": { ... }
}
```

#### DELETE /api/social/posts/:postId/comments/:commentId
Delete comment (requires authentication, user must own comment).

**Response:**
```json
{
  "message": "Comment deleted successfully"
}
```

### Stories

#### GET /api/social/stories
Get all non-expired stories.

**Response:**
```json
{
  "stories": [
    {
      "_id": "...",
      "userId": "...",
      "userName": "John Doe",
      "userAvatar": "/uploads/avatar.jpg",
      "imageUrl": "/uploads/story1.jpg",
      "viewed": false,
      "createdAt": "2026-04-14T10:40:00Z",
      "expiresAt": "2026-04-15T10:40:00Z"
    }
  ]
}
```

#### POST /api/social/stories
Create a new story (requires authentication).

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Form Data:**
- `image`: Single image file (required)

**Response:**
```json
{
  "story": {
    "_id": "...",
    ...
  }
}
```

#### POST /api/social/stories/:storyId/view
Mark story as viewed (requires authentication).

**Response:**
```json
{
  "story": { ... }
}
```

#### POST /api/social/stories/:storyId/react
Add emoji reaction to story (requires authentication).

**Body:**
```json
{
  "emoji": "❤️"
}
```

**Response:**
```json
{
  "story": { ... }
}
```

## Testing with Postman/cURL

### 1. Create a Post with Images

```bash
curl -X POST http://localhost:5000/api/social/posts \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -F "content=My first post!" \
  -F "images=@/path/to/image1.jpg" \
  -F "images=@/path/to/image2.jpg"
```

### 2. Get All Posts

```bash
curl http://localhost:5000/api/social/posts?page=1&limit=10
```

### 3. Create a Story

```bash
curl -X POST http://localhost:5000/api/social/stories \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -F "image=@/path/to/story.jpg"
```

### 4. Get All Stories

```bash
curl http://localhost:5000/api/social/stories
```

### 5. Like a Post

```bash
curl -X POST http://localhost:5000/api/social/posts/POST_ID/like \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN"
```

### 6. Add Comment

```bash
curl -X POST http://localhost:5000/api/social/posts/POST_ID/comments \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"content": "Great post!"}'
```

### 7. React to Post

```bash
curl -X POST http://localhost:5000/api/social/posts/POST_ID/react \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"emoji": "👍"}'
```

## Key Features

### 1. **File Upload with Validation**
- Images: JPEG, PNG, GIF, WebP (max 5MB each)
- Attachments: PDF, Word, Excel, Text (max 5MB each)
- Max 10 images per post
- Automatic filename generation to prevent conflicts

### 2. **Story Auto-Expiry**
- Stories automatically expire after 24 hours
- MongoDB TTL index handles automatic deletion
- No manual cleanup needed

### 3. **User Information Caching**
- Post, comment, and story creation captures user name and avatar
- Prevents issues if user profile changes later
- Improves query performance

### 4. **Like/Unlike Toggle**
- Same endpoint toggles like on/off
- Maintains array of user IDs who liked
- Atomic increment/decrement of like counter

### 5. **Emoji Reactions**
- Multiple reactions per post/story
- Each user can react once per emoji type
- Same endpoint removes reaction if already exists

### 6. **Pagination**
- Posts paginated (default 10 per page)
- Efficient database queries with sorting
- Supports `page` and `limit` query parameters

### 7. **Comment Threading**
- Comments linked directly to posts via postId
- Post comment count auto-incremented/decremented
- Comments sorted chronologically

## Database Indexes

Automatically created for performance:

```javascript
// Post indexes
postSchema.index({ createdAt: -1 });  // For sorting by date
postSchema.index({ userId: 1 });      // For user's posts

// Story indexes + TTL
storySchema.index({ userId: 1, createdAt: -1 });
storySchema.index({ createdAt: -1 });
storySchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 }); // Auto-delete

// Comment indexes
commentSchema.index({ postId: 1, createdAt: -1 }); // Find post comments
commentSchema.index({ userId: 1 });                // Find user's comments
```

## Error Handling

All endpoints return appropriate HTTP status codes:
- `200`: Success
- `201`: Created
- `400`: Bad request (missing fields, invalid format)
- `403`: Forbidden (not authorized to perform action)
- `404`: Not found (post, story, comment doesn't exist)
- `500`: Server error

Error response format:
```json
{
  "error": "Error description"
}
```

## Security Notes

1. **Authentication Required**: All write operations (POST, DELETE) require valid JWT token
2. **Authorization**: Users can only delete their own posts/comments
3. **File Validation**: Strict MIME type and file size checks
4. **Input Validation**: Content length limits (5000 for posts, 1000 for comments)
5. **Rate Limiting**: Should be added for production (recommended: express-rate-limit)
6. **CORS**: Already configured for your frontend URL

## Production Deployment Checklist

- [ ] Set valid MongoDB URI in `.env`
- [ ] Add rate limiting middleware
- [ ] Implement image optimization/compression
- [ ] Set up CDN for uploaded files
- [ ] Configure proper file storage (S3, etc.)
- [ ] Add logging for all API operations
- [ ] Implement database backup strategy
- [ ] Add API monitoring/alerting
- [ ] Test file upload limits
- [ ] Validate JWT token expiry
- [ ] Add HTTPS/TLS (for production)

---

**Created**: April 14, 2026
**Status**: Ready for integration and testing
