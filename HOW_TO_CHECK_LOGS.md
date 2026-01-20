# How to Check Flutter App Logs

## Method 1: Using Flutter Run (Recommended for Development)

### Step 1: Connect Your Device
- Connect your Android device via USB
- Enable USB Debugging on your device
- Or use an Android emulator

### Step 2: Run the App with Logs
```bash
cd dhamma_apk
flutter run
```

### Step 3: View Logs
- Logs will appear in your terminal/command prompt
- Look for messages starting with emojis:
  - 📱 App badge related logs
  - 🔔 Notification related logs
  - ✅ Success messages
  - ❌ Error messages
  - ⚠️ Warning messages

### Step 4: Filter Logs (Optional)
To see only badge-related logs:
```bash
flutter run | grep -i "badge"
```

Or on Windows PowerShell:
```powershell
flutter run | Select-String -Pattern "badge"
```

---

## Method 2: Using Android Logcat (For Release APK)

### Step 1: Install ADB
ADB (Android Debug Bridge) comes with Android Studio SDK Platform Tools.

### Step 2: Connect Device
```bash
adb devices
```

### Step 3: View Logs
```bash
# View all logs
adb logcat

# Filter for Flutter/Dart logs only
adb logcat | grep -i "flutter\|dart"

# Filter for badge-related logs
adb logcat | grep -i "badge"

# Filter for notification logs
adb logcat | grep -i "notification\|FCM"
```

### Step 4: Save Logs to File
```bash
# Save all logs to file
adb logcat > app_logs.txt

# Save filtered logs
adb logcat | grep -i "badge\|notification" > badge_logs.txt
```

---

## Method 3: Using Flutter DevTools (Advanced)

### Step 1: Run App
```bash
flutter run
```

### Step 2: Open DevTools
- Press `d` in the terminal where `flutter run` is active
- Or visit: `http://localhost:9100` (URL will be shown in terminal)

### Step 3: View Logs
- Go to "Logging" tab in DevTools
- Filter by "badge" or "notification"

---

## Method 4: Check Logs in Android Studio / VS Code

### Android Studio:
1. Open the project in Android Studio
2. Run the app (Shift+F10)
3. Open "Logcat" tab at the bottom
4. Filter by: `flutter`, `dart`, or `badge`

### VS Code:
1. Install "Flutter" extension
2. Run the app (F5)
3. Open "Debug Console" tab
4. Logs will appear there

---

## What to Look For in Logs

### Badge Support Check:
```
📱 App badge support check: true/false
```

### Badge Updates:
```
📱 Updating app badge...
📱 Current unread count: X
📱 App badge supported: true/false
📱 Setting badge count to: X
✅ Badge count set to X
```

### Notification Receipt:
```
🔔 Handling notification in provider
📬 Handling FCM notification
📊 Total notifications: X, Unread: Y
```

### Errors:
```
❌ Error updating badge count: [error message]
⚠️ App badge is NOT supported on this device/launcher
```

---

## Quick Test Commands

### Test Badge Support:
```bash
# Run app and watch for badge support message
flutter run | Select-String -Pattern "badge support"
```

### Test Notification Flow:
```bash
# Watch for notification handling
flutter run | Select-String -Pattern "notification|badge"
```

### Save All Logs:
```bash
# Save to file for later analysis
flutter run > flutter_logs.txt 2>&1
```

---

## Troubleshooting

### If logs don't show:
1. **Check USB Debugging**: Ensure it's enabled on your device
2. **Check ADB Connection**: Run `adb devices` to verify
3. **Restart ADB**: `adb kill-server && adb start-server`
4. **Check Flutter Doctor**: `flutter doctor -v`

### If badge logs are missing:
1. **Check Log Level**: Ensure debug logs are enabled
2. **Rebuild App**: `flutter clean && flutter pub get && flutter run`
3. **Check Permissions**: Ensure notification permissions are granted

---

## Example Log Output

When everything works correctly, you should see:

```
🔔 Initializing notification provider...
📱 App badge support check: true
✅ FCM initialized
✅ Notification service connected
👂 Notification listener registered
📱 App badge initialized
📬 Handling FCM notification
✅ Created FCM notification: ပို့စ်အသစ်
📊 Total notifications: 1, Unread: 1
📱 Updating app badge...
📱 Current unread count: 1
📱 App badge supported: true
📱 Setting badge count to: 1
✅ Badge count set to 1
✅ Badge update confirmed
🔔 FCM notification handled successfully
```

---

## For Release APK Testing

If you're testing a release APK (not debug build):

1. **Install APK on device**
2. **Connect via USB**
3. **Run logcat**:
   ```bash
   adb logcat | grep -i "flutter\|dart\|badge\|notification"
   ```
4. **Trigger a notification** (create post from admin)
5. **Watch the logs** for badge-related messages

---

## Tips

- **Use filters** to reduce log noise
- **Save logs** to file for later analysis
- **Check both** badge support and update messages
- **Test on different devices** to see launcher differences

