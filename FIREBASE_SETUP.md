# Firebase Cloud Messaging (FCM) Setup Guide

This guide will help you set up Firebase Cloud Messaging for push notifications in the Flutter app.

## Quick Reference: Where to Find Server Key/Credentials

### For Service Account (V1 API - Recommended):
1. Firebase Console → **Project Settings** (gear icon) → **Service accounts** tab
2. Click **"Generate new private key"**
3. Download the JSON file

### For Legacy Server Key (Deprecated):
1. Firebase Console → **Project Settings** → **Cloud Messaging** tab
2. Under **"Cloud Messaging API (Legacy)"** section
3. Copy the **"Server key"**

**Your Project Info:**
- Project ID: `notification-88e7c`
- Project Number: `731040393302` (this is also your Sender ID)

## Prerequisites

1. A Google account
2. Android Studio (for Android setup)
3. Flutter SDK installed

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Enter project name (e.g., "Parayana Dhamma Center")
4. Follow the setup wizard
5. Enable Google Analytics (optional)

## Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" and select Android
2. Enter package name: `com.example.thitsaintchoun_apk`
   - **This matches the `applicationId` in `android/app/build.gradle.kts` (line 25)**
   - **Current package name**: `com.example.thitsaintchoun_apk`
   - **To verify**: Check `android/app/build.gradle.kts` line 25: `applicationId = "com.example.thitsaintchoun_apk"`
   - **If you change the package name in `build.gradle.kts`, you must update it in Firebase too**
3. Register app
4. Download `google-services.json`
5. Place the file in: `android/app/google-services.json`
   - **Important**: The file must be named exactly `google-services.json` (not `google-services.json.txt`)**
   - **File location**: `dhamma_apk/android/app/google-services.json`

## Step 3: Configure Android

The Android configuration is already set up in the code:
- ✅ Google Services plugin added to `build.gradle.kts`
- ✅ FCM permissions added to `AndroidManifest.xml`
- ✅ FCM service configured

## Step 4: Get FCM Credentials for Laravel Backend

### Option A: Service Account (Recommended - V1 API)

**For Firebase Cloud Messaging API (V1) - Recommended:**

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Click on **"Service accounts"** tab
3. Click **"Generate new private key"** button
4. Download the JSON file (e.g., `notification-88e7c-firebase-adminsdk-xxxxx.json`)
5. Save this file securely (you'll need it for Laravel backend)
6. **Note**: This is the recommended method for the V1 API

### Option B: Legacy Server Key (Deprecated)

**For Legacy API (Deprecated - Use only if needed):**

1. In Firebase Console, go to **Project Settings**
2. Click on **"Cloud Messaging"** tab
3. Under **"Cloud Messaging API (Legacy)"** section, you'll see the **"Server key"**
4. **Warning**: Legacy API is deprecated (June 20, 2024). Use Service Account instead.

### Important Notes:

- **Project Number**: `731040393302` (from your google-services.json)
- **Project ID**: `notification-88e7c` (from your google-services.json)
- **Sender ID**: `731040393302` (same as Project Number)
- **Use Service Account (V1 API)** for new implementations

## Step 5: Update Laravel Backend

You'll need to update the Laravel `NotificationService` to send FCM push notifications. Here's what you need to add:

### Install Laravel FCM Package

```bash
composer require laravel-notification-channels/fcm
```

### Update NotificationService.php

Add FCM sending capability to send push notifications when creating posts, lessons, etc.

## Step 6: Test FCM

1. Build and run the app:
   ```bash
   flutter pub get
   flutter run
   ```

2. Check logs for FCM token:
   - Look for: `✅ FCM token obtained: [token]`
   - The token will be saved automatically

3. Send a test notification from Firebase Console:
   - Go to Cloud Messaging in Firebase Console
   - Click "Send your first message"
   - Enter title and message
   - Select your app
   - Send

## Step 7: Integrate with Laravel

Update your Laravel `NotificationService` to send FCM notifications. You can use the FCM token stored in the app to send targeted notifications.

### Configure Laravel for FCM

1. **Service Account JSON File:**
   - ✅ Already placed at: `storage/app/firebase/notification-88e7c-c50770d57b15.json`
   - **Service Account Email**: `firebase-adminsdk-fbsvc@notification-88e7c.iam.gserviceaccount.com`
   - **Project ID**: `notification-88e7c`

2. **Install Firebase PHP SDK:**
   ```bash
   composer require kreait/firebase-php
   composer update
   ```

3. **Note about Private Key:**
   - The private key `3DvH0qpeubQn1YCZ8k5h1BsYH5ltrt18erduCVEW2p4` is for **Web Push certificates** (web browsers)
   - For Android FCM, use the **Service Account JSON file** (already configured)

### Example Laravel FCM Integration (Using Service Account - V1 API)

```php
use Kreait\Firebase\Factory;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

public function sendFCMNotification($fcmToken, $title, $body, $data = [])
{
    try {
        $factory = (new Factory)
            ->withServiceAccount(storage_path('app/firebase/your-service-account.json'));

        $messaging = $factory->createMessaging();

        $notification = Notification::create($title, $body);
        
        $message = CloudMessage::withTarget('token', $fcmToken)
            ->withNotification($notification)
            ->withData($data);

        $messaging->send($message);
        
        return true;
    } catch (\Exception $e) {
        \Log::error('FCM notification failed: ' . $e->getMessage());
        return false;
    }
}
```

### Alternative: Using Legacy Server Key (Not Recommended)

If you must use the legacy API:

```php
use LaravelFCM\Message\OptionsBuilder;
use LaravelFCM\Message\PayloadDataBuilder;
use LaravelFCM\Message\PayloadNotificationBuilder;
use FCM;

// In config/fcm.php, set your server key
public function sendFCMNotification($fcmToken, $title, $body, $data = [])
{
    $notificationBuilder = new PayloadNotificationBuilder($title);
    $notificationBuilder->setBody($body)->setSound('default');

    $dataBuilder = new PayloadDataBuilder();
    $dataBuilder->addData($data);

    $optionBuilder = new OptionsBuilder();
    $optionBuilder->setTimeToLive(60*20);

    $notification = $notificationBuilder->build();
    $data = $dataBuilder->build();
    $option = $optionBuilder->build();

    $downstreamResponse = FCM::sendTo($fcmToken, $option, $notification, $data);

    return $downstreamResponse->numberSuccess();
}
```

## Troubleshooting

### FCM Token Not Generated

1. Make sure `google-services.json` is in `android/app/` directory
2. Check that Google Services plugin is applied in `build.gradle.kts`
3. Rebuild the app: `flutter clean && flutter pub get && flutter run`

### Notifications Not Received

1. Check device notification permissions (Android 13+)
2. Verify FCM token is generated (check logs)
3. Check Firebase Console for delivery status
4. Ensure app is not in battery optimization mode

### Build Errors

1. Make sure `google-services.json` is present
2. Verify `compileSdkVersion` is 34 or higher
3. Check that all dependencies are updated: `flutter pub upgrade`

## Notes

- FCM works even when the app is closed (background notifications)
- Socket.IO notifications work when the app is open (real-time)
- Both systems work together for complete notification coverage
- FCM tokens are automatically refreshed when needed

## Next Steps

1. Set up FCM in Laravel backend
2. Store FCM tokens in database (optional, for targeted notifications)
3. Send FCM notifications when admin creates posts/lessons/etc.
4. Test on a physical device (emulators may have issues with FCM)

