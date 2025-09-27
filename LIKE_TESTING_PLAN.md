# Like Functionality Testing Plan

## 🎯 Objective
Test and verify that the like/unlike functionality works correctly after fixing the API endpoints.

## 🔧 Changes Made

### 1. Updated API Service (`lib/services/api_service.dart`)
- **Fixed likePost()**: Now tries multiple endpoints in sequence
- **Fixed unlikePost()**: Now tries multiple endpoints in sequence
- **Added fallback logic**: If all endpoints fail, uses local fallback
- **Improved error handling**: Better logging and error messages

### 2. Updated User Like Service (`lib/services/user_like_service.dart`)
- **Fixed likeUserPost()**: Now tries multiple endpoints in sequence
- **Fixed unlikeUserPost()**: Now tries multiple endpoints in sequence
- **Added local storage**: Maintains like status locally for persistence
- **Improved error handling**: Better logging and error messages

### 3. Endpoints Being Tested
1. `http://103.14.120.163:8081/api/posts/{postId}/like`
2. `http://103.14.120.163:8081/api/feed/like/{postId}`
3. `http://103.14.120.163:8081/api/user/posts/{postId}/like`
4. `https://api-rgram1.vercel.app/api/posts/{postId}/like`

## 🧪 Testing Steps

### Step 1: Run the App
```bash
flutter run
```

### Step 2: Navigate to Home Screen
- Open the app
- Go to the home screen where posts are displayed

### Step 3: Test Like Functionality
1. **Find a post** on the home screen
2. **Tap the like button** (heart icon)
3. **Verify the response**:
   - Check console logs for API calls
   - Verify like count increases
   - Verify heart icon changes to filled (red)
   - Check for success message

### Step 4: Test Unlike Functionality
1. **Tap the like button again** (should be filled/red now)
2. **Verify the response**:
   - Check console logs for API calls
   - Verify like count decreases
   - Verify heart icon changes to outline
   - Check for success message

### Step 5: Test Persistence
1. **Navigate away** from the home screen
2. **Return to home screen**
3. **Verify like status** is maintained (if using local storage)

## 📊 Expected Results

### Success Indicators
- ✅ API calls succeed with 200/201 status
- ✅ Like count updates correctly
- ✅ Heart icon changes state
- ✅ Success messages appear
- ✅ No 404 "Post not found" errors

### Fallback Indicators
- ⚠️ If all API endpoints fail, local fallback should work
- ⚠️ Like status should be maintained locally
- ⚠️ User should see "liked locally" message

## 🐛 Debugging

### Console Logs to Watch For
```
Trying like endpoint: [URL]
Like Post API - URL: [URL]
Like Post API response status: [STATUS]
Like Post API response body: [RESPONSE]
Like Post API succeeded with endpoint: [URL]
```

### Common Issues
1. **404 Errors**: Post ID might not exist on server
2. **401 Errors**: Authentication token might be invalid
3. **Network Errors**: Check internet connection
4. **Local Fallback**: Should work even if API fails

## 🎉 Success Criteria
- [ ] Like button works without 404 errors
- [ ] Unlike button works without 404 errors
- [ ] Like count updates correctly
- [ ] Visual feedback is immediate
- [ ] Fallback works when API fails
- [ ] No crashes or exceptions

## 📝 Test Results
*To be filled after testing*

### Test 1: Like Functionality
- **Status**: [PENDING/SUCCESS/FAILED]
- **API Endpoint Used**: [URL]
- **Response**: [SUCCESS/FAILED]
- **Notes**: [Any issues or observations]

### Test 2: Unlike Functionality
- **Status**: [PENDING/SUCCESS/FAILED]
- **API Endpoint Used**: [URL]
- **Response**: [SUCCESS/FAILED]
- **Notes**: [Any issues or observations]

### Test 3: Persistence
- **Status**: [PENDING/SUCCESS/FAILED]
- **Local Storage**: [WORKING/NOT WORKING]
- **Notes**: [Any issues or observations]

## 🔄 Next Steps
1. Run the app and test like functionality
2. Document any issues found
3. Fix any remaining problems
4. Verify all tests pass
5. Clean up test files
