# Baba Ji Reel Like API - Curl Commands Reference

## Base URL
```
http://103.14.120.163:8081/api/baba-pages/{BABA_PAGE_ID}/like
```

## Working Example (From Your Test)
- **Baba Page ID**: `68da2be0cffda6e29eb5332f`
- **Reel ID**: `68da64cd8cee67f3b8fbe189`
- **User ID**: `68da2be0cffda6e29eb5332f`

---

## 1. Like a Baba Ji Reel/Video

```bash
curl --location 'http://103.14.120.163:8081/api/baba-pages/68da2be0cffda6e29eb5332f/like' \
--header 'Content-Type: application/json' \
--data '{
    "contentId": "68da64cd8cee67f3b8fbe189",
    "contentType": "video",
    "userId": "68da2be0cffda6e29eb5332f",
    "action": "like"
}'
```

**Expected Response:**
```json
{
    "success": true,
    "message": "Content liked successfully",
    "data": {
        "contentId": "68da64cd8cee67f3b8fbe189",
        "contentType": "video",
        "isLiked": true,
        "likesCount": 1
    }
}
```

---

## 2. Unlike a Baba Ji Reel/Video

```bash
curl --location 'http://103.14.120.163:8081/api/baba-pages/68da2be0cffda6e29eb5332f/like' \
--header 'Content-Type: application/json' \
--data '{
    "contentId": "68da64cd8cee67f3b8fbe189",
    "contentType": "video",
    "userId": "68da2be0cffda6e29eb5332f",
    "action": "unlike"
}'
```

**Expected Response:**
```json
{
    "success": true,
    "message": "Content unliked successfully",
    "data": {
        "contentId": "68da64cd8cee67f3b8fbe189",
        "contentType": "video",
        "isLiked": false,
        "likesCount": 0
    }
}
```

---

## 3. Get Like Status for Baba Ji Reel/Video

```bash
curl --location 'http://103.14.120.163:8081/api/baba-pages/68da2be0cffda6e29eb5332f/like?contentId=68da64cd8cee67f3b8fbe189&contentType=video&userId=68da2be0cffda6e29eb5332f' \
--header 'Content-Type: application/json'
```

**Expected Response:**
```json
{
    "success": true,
    "message": "Like status retrieved",
    "data": {
        "contentId": "68da64cd8cee67f3b8fbe189",
        "contentType": "video",
        "isLiked": true,
        "likesCount": 1
    }
}
```

---

## Generic Template

Replace the following placeholders with your actual values:

```bash
# Like
curl --location 'http://103.14.120.163:8081/api/baba-pages/{BABA_PAGE_ID}/like' \
--header 'Content-Type: application/json' \
--data '{
    "contentId": "{REEL_VIDEO_ID}",
    "contentType": "video",
    "userId": "{USER_ID}",
    "action": "like"
}'

# Unlike
curl --location 'http://103.14.120.163:8081/api/baba-pages/{BABA_PAGE_ID}/like' \
--header 'Content-Type: application/json' \
--data '{
    "contentId": "{REEL_VIDEO_ID}",
    "contentType": "video",
    "userId": "{USER_ID}",
    "action": "unlike"
}'

# Get Status
curl --location 'http://103.14.120.163:8081/api/baba-pages/{BABA_PAGE_ID}/like?contentId={REEL_VIDEO_ID}&contentType=video&userId={USER_ID}' \
--header 'Content-Type: application/json'
```

---

## Parameters Explanation

- **BABA_PAGE_ID**: The ID of the Baba Ji page
- **REEL_VIDEO_ID**: The ID of the specific reel/video
- **USER_ID**: The ID of the user performing the action
- **contentType**: Always "video" for reels/videos
- **action**: "like" or "unlike"

---

## Response Data Fields

- **success**: Boolean indicating if the request was successful
- **message**: Human-readable message about the operation
- **data.contentId**: The ID of the content that was liked/unliked
- **data.contentType**: The type of content ("video")
- **data.isLiked**: Boolean indicating if the user has liked this content
- **data.likesCount**: Total number of likes for this content

---

## Integration Status

✅ **API Connection Verified**: The API is working correctly  
✅ **Implementation Complete**: Our BabaLikeService matches this API format  
✅ **Widget Integration**: All video widgets are connected to this API  
✅ **Real-time Updates**: Like counts update immediately  
✅ **Error Handling**: Comprehensive error handling implemented  

The Baba Ji reel like functionality is fully connected and working with this API!
