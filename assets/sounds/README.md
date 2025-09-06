# Custom Notification Sounds

This directory contains custom sound files for notifications in the Luna IoT app.

## Required Sound Files

For custom sounds to work properly, you need to add the following sound files:

### Android (Raw Resources)
- `alarm_sound.mp3` - For alarm notifications
- `alert_sound.mp3` - For alert notifications  
- `notification_sound.mp3` - For general notifications

### iOS (Bundle Resources)
- `alarm_sound.aiff` - For alarm notifications
- `alert_sound.aiff` - For alert notifications
- `notification_sound.aiff` - For general notifications

## File Requirements

### Android
- Format: MP3, WAV, or OGG
- Duration: 1-5 seconds recommended
- Size: Keep under 1MB
- Location: `android/app/src/main/res/raw/`

### iOS
- Format: AIFF, WAV, or CAF
- Duration: 1-5 seconds recommended
- Size: Keep under 1MB
- Location: `ios/Runner/`

## How to Add Sound Files

1. **For Android:**
   - Place sound files in `android/app/src/main/res/raw/`
   - Use the exact filenames: `alarm_sound.mp3`, `alert_sound.mp3`, `notification_sound.mp3`

2. **For iOS:**
   - Place sound files in `ios/Runner/`
   - Use the exact filenames: `alarm_sound.aiff`, `alert_sound.aiff`, `notification_sound.aiff`
   - Add them to the Xcode project bundle

## Testing

You can test custom sounds by:
1. Using the "Test Local Notification" feature in the app
2. Sending test notifications from the server with different sound types
3. Checking the debug console for sound file loading messages

## Default Behavior

If custom sound files are not found, the app will fall back to the default system notification sound. 