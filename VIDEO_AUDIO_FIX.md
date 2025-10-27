# Video Audio Fix - Reels Section Only

## Problem
Video audio was playing in various places throughout the app, not just in the reels section. User wanted audio to only play when viewing videos in the reels section.

## Solution
Modified video playback settings across the app:

### Reels Section - Audio Enabled ✅
- **File**: `lib/screens/reels_screen.dart`
- **Change**: Explicitly set `muted: false` for videos in the reels section
- **Result**: When users are viewing videos in the reels section, audio is enabled

### Profile Reels - Audio Disabled ✅
- **File**: `lib/widgets/profile_reel_widget.dart`
- **Change**: Changed `muted: false` to `muted: true`
- **Result**: Videos in user profiles don't have audio

### Baba Page Videos - Audio Disabled ✅
- **File**: `lib/widgets/in_app_video_widget.dart`
- **Change**: Changed `muted: false` to `muted: true`
- **Result**: Videos in Baba page details don't have audio

### Home Feed Posts - Already Correct ✅
- **Files**: 
  - `lib/widgets/enhanced_post_widget.dart` - `muted: true`
  - `lib/widgets/post_widget.dart` - `muted: true`
- **Result**: Videos in the home feed don't have audio

### Other Video Locations - Already Correct ✅
- **BabaPageReelWidget**: `muted: true` (correct)
- **VideoReelWidget**: `muted: true` (correct)
- **BabaPageReelWidget**: `muted: true` (correct)

### Special Cases - Keep Audio ✅
- **Post Full View**: `muted: false` (when opening a reel for full view)
- **Story Viewer**: `muted: false` (stories can have audio)
- **Chat Screen**: `muted: false` (video messages should have audio)

## Summary of Changes

| Location | Before | After | Notes |
|----------|--------|-------|-------|
| Reels Screen | Default (false) | `muted: false` | Audio enabled - main reels viewing |
| Profile Reels | `muted: false` | `muted: true` | Audio disabled |
| Baba Page Videos | `muted: false` | `muted: true` | Audio disabled |
| Home Feed Posts | `muted: true` | `muted: true` | Already correct |
| Post Widget | `muted: true` | `muted: true` | Already correct |
| Post Full View | `muted: false` | `muted: false` | Keep audio for full view |
| Story Viewer | `muted: false` | `muted: false` | Keep audio for stories |

## Result
Now audio only plays:
- ✅ When viewing videos in the Reels section
- ✅ When opening a post/reel in full view
- ✅ When viewing stories with sound
- ❌ NOT when scrolling through home feed
- ❌ NOT when viewing profiles
- ❌ NOT when viewing Baba pages

## Testing
1. Go to Reels section → Audio should be enabled
2. View profile → Videos should be muted
3. Browse home feed → Videos should be muted
4. Open a video in full view → Audio should be enabled
5. View Baba pages → Videos should be muted

