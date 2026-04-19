# Social Feed - Complete Integration Guide

## ✅ What's Been Implemented

### Backend (Node.js/Express)
- ✅ Database models (Post, Story, Comment)
- ✅ API controllers with full business logic
- ✅ Routes for all social operations
- ✅ File upload middleware (multer) with validation
- ✅ Integration with existing server
- ✅ MongoDB database operations

### Frontend (Flutter)
- ✅ Models, services, and providers
- ✅ UI screens (Feed, Create Post, Create Story, Story Viewer, Comments)
- ✅ Modern design with green theme
- ✅ Animations and interactions
- ✅ AuthProvider extended with user info getters

## 🚀 Setup Instructions

### Step 1: Backend Setup

1. **Install Dependencies**
```bash
cd backend
npm install
# or if multer is missing
npm install multer
```

2. **Verify `.env` file** has MongoDB URI:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/orelax
```

3. **Create uploads directory** (already configured in upload.js):
```bash
mkdir uploads
```

4. **Test Backend** (start Node server):
```bash
npm run dev
# or
npm start
```

Should see: `✅ MongoDB connected successfully`

### Step 2: Verify Frontend Setup

1. **Check dependencies** in `pubspec.yaml`:
```yaml
dependencies:
  image_picker: ^1.0.0
  intl: ^0.19.0
  google_fonts: ^6.0.0
```

2. **Run Flutter pub get**:
```bash
cd orelax
flutter pub get
```

3. **Update `.env` or config** if needed:
```dart
// In social_api_service.dart
static const String baseUrl = 'http://localhost:5000/api';
```

### Step 3: Test the Integration

#### Test 1: Create a Post

**Frontend Flow:**
1. Navigate to `/feed` route
2. Tap "What's on your mind?"
3. Type message: "Test post"
4. Tap "Post"

**What Happens Backend:**
1. POST to `/api/social/posts`
2. Creates Post document in MongoDB
3. Returns created post with ID

**Expected Result:**
- Post appears at top of feed
- All fields properly saved to database

#### Test 2: Create a Story

**Frontend Flow:**
1. Tap "Add Story" button
2. Select image from camera/gallery
3. Tap "Post"

**What Happens Backend:**
1. POST to `/api/social/stories`
2. Uploads image to `/uploads` directory
3. Creates Story document with 24-hour expiry
4. Returns story object

**Expected Result:**
- Story appears in carousel
- Auto-expires after 24 hours

#### Test 3: Like a Post

**Frontend Flow:**
1. Tap heart icon on any post

**What Happens Backend:**
1. POST to `/api/social/posts/{postId}/like`
2. Toggles user ID in `likedBy` array
3. Updates `likes` count
4. Returns updated post

**Expected Result:**
- Heart turns red
- Like count increments/decrements

#### Test 4: Add Comment

**Frontend Flow:**
1. Tap comment icon on post
2. Type comment
3. Tap send button

**What Happens Backend:**
1. POST to `/api/social/posts/{postId}/comments`
2. Creates Comment document
3. Updates post `comments` count
4. Returns comment object

**Expected Result:**
- Comment appears below post
- Comment count increment shown

## 📋 Database Verification

### Check MongoDB Collections

```javascript
// Connect to MongoDB and check:
db.posts.find().pretty()              // See all posts
db.stories.find().pretty()            // See all stories
db.comments.find().pretty()           // See all comments

// Check specific post with comments
db.comments.find({ postId: ObjectId("...") }).pretty()

// Check story view count
db.stories.findOne({ _id: ObjectId("...") })
```

### Sample Data Queries

```javascript
// Count posts
db.posts.countDocuments()

// Get posts created today
db.posts.find({ 
  createdAt: { 
    $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) 
  } 
})

// Get non-expired stories
db.stories.find({ 
  expiresAt: { $gt: new Date() } 
})

// Check if story TTL index exists
db.stories.getIndexes()
```

## 🔍 Troubleshooting

### Issue: "Post not created" / 500 error

**Check:**
1. MongoDB connection is active
2. Auth middleware is working
3. User ID is valid
4. Content is not empty

**Debug:**
```bash
# Check server logs for detailed error
# Look for: "Error creating post:"
```

### Issue: "Images not uploading"

**Check:**
1. `/uploads` directory exists
2. File size < 5MB
3. Image format is JPEG/PNG/GIF/WebP
4. Multer middleware is loaded

**Debug:**
```javascript
// In server.js, check upload middleware is registered
app.post('/api/social/posts', auth, upload.array('images', 10), ...)
```

### Issue: "Stories not expiring"

**Check:**
1. MongoDB TTL index is created
2. Story `expiresAt` is set
3. 24 hours have passed

**Verify TTL Index:**
```javascript
db.stories.getIndexes()
// Should show: "expiresAt_1" with "expireAfterSeconds": 0
```

### Issue: Frontend can't connect to backend

**Check:**
1. Backend is running on port 5000
2. CORS is enabled
3. API base URL is correct
4. Network connectivity

**Test from Terminal:**
```bash
curl http://localhost:5000/api/health
# Should return: { "status": "OK", "message": "ORELAX API is running" }
```

## 📊 API Response Examples

### Create Post - Success
```json
{
  "post": {
    "_id": "507f1f77bcf86cd799439011",
    "userId": "507f1f77bcf86cd799439012",
    "userName": "John Doe",
    "userAvatar": "/uploads/avatar.jpg",
    "content": "Great day!",
    "imageUrls": ["/uploads/img1.jpg"],
    "likes": 0,
    "comments": 0,
    "shares": 0,
    "createdAt": "2026-04-14T10:30:00.000Z"
  }
}
```

### Like Post - Success
```json
{
  "post": {
    ...previous fields...,
    "likes": 5,
    "likedBy": ["userId1", "userId2", ...]
  }
}
```

### Get Posts - Success
```json
{
  "posts": [
    { ...post1... },
    { ...post2... }
  ],
  "pagination": {
    "current": 1,
    "total": 3,
    "count": 10
  }
}
```

### Error Response - Example
```json
{
  "error": "Post content is required"
}
```

## 🔐 Security Checklist

- ✅ JWT authentication required for write operations
- ✅ File type validation (MIME types)
- ✅ File size limits (5MB)
- ✅ User authorization checks (own resources only)
- ✅ Input validation (content length limits)
- ✅ CORS configured for frontend URL
- ⚠️ TODO: Rate limiting for production
- ⚠️ TODO: Image optimization before storage
- ⚠️ TODO: HTTPS for production

## 🚀 Production Deployments

### Deploy Backend (Heroku/Railway/Render)

```bash
# Add to package.json
"engines": {
  "node": "18.x"
}

# Deploy
git push heroku main
```

### Deploy Cloud Storage

Instead of local `/uploads`, configure a cloud storage provider and update `upload.js` accordingly.

### Configure CDN

```javascript
// Update socializController.js
imageUrls: req.files?.map(f => `https://cdn.example.com/${f.filename}`)
```

## 📈 Performance Optimization

### Database Indexes Already Set

```javascript
// Automatic indexes created:
- postSchema.index({ createdAt: -1 })     // Fast sorting
- postSchema.index({ userId: 1 })         // User's posts
- storySchema.index({ expiresAt: 1 })     // TTL deletion
```

### Frontend Optimization

```dart
// Image caching in Flutter
Image.network(
  imageUrl,
  cacheWidth: 500,  // Cache scaled version
  cacheHeight: 500,
)
```

### Query Optimization

```javascript
// Use .lean() for read-only queries
Post.find().lean()  // Returns plain objects, not Mongoose docs

// Pagination prevents loading all posts
skip: (page - 1) * limit
limit: 10
```

## 🧪 Integration Testing Script

### Postman Collection (export/import this)

```json
{
  "name": "Social Feed API",
  "item": [
    {
      "name": "Get Posts",
      "request": {
        "method": "GET",
        "url": "{{baseUrl}}/social/posts"
      }
    },
    {
      "name": "Create Post",
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/social/posts",
        "header": {"Authorization": "Bearer {{token}}"},
        "body": {
          "mode": "formdata",
          "formdata": [
            {"key": "content", "value": "Test post"},
            {"key": "images", "type": "file"}
          ]
        }
      }
    },
    {
      "name": "Like Post",
      "request": {
        "method": "POST",
        "url": "{{baseUrl}}/social/posts/{{postId}}/like",
        "header": {"Authorization": "Bearer {{token}}"}
      }
    }
  ]
}
```

## 📞 Next Steps

1. **Test locally** - Run all integration tests
2. **Monitor logs** - Watch for errors
3. **Verify database** - Check MongoDB collections
4. **Deploy** - Move to production when ready
5. **Monitor** - Set up error tracking
6. **Iterate** - Add more features as needed

---

**Integration Date**: April 14, 2026
**Status**: Complete & Ready for Testing
**Next Phase**: Real-time updates with Socket.io
