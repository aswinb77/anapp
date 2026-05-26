# Setup: Restoring Credentials

Your Firebase configuration files were removed from Git history for security. You need to restore them locally to build and run the app.

## ⚠️ Important

These files contain sensitive credentials and should **NEVER be committed to Git**. They are already in `.gitignore`.

## How to Restore

### Option 1: Copy from Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `movie-2e707`

#### For Android:
- Click Project Settings → Download `google-services.json`
- Place it at: `android/app/google-services.json`

#### For iOS:
- Click Project Settings → Download `GoogleService-Info.plist`
- Place it at: `ios/Runner/GoogleService-Info.plist`

### Option 2: Use Templates

If you have backups of the credentials files:
1. Rename the template files:
   ```bash
   mv android/app/google-services.json.template android/app/google-services.json
   mv ios/Runner/GoogleService-Info.plist.template ios/Runner/GoogleService-Info.plist
   ```

2. Open each file and replace `YOUR_*` placeholders with your actual values

### Option 3: Restore from Local Backup

If you have a backup copy of these files on your machine, copy them to:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

## Verify

After restoring, verify the files exist:
```bash
ls -la android/app/google-services.json
ls -la ios/Runner/GoogleService-Info.plist
```

Then try building:
```bash
flutter pub get
flutter build apk --release
```

## Security Notes

✓ All API keys have been removed from Git history  
✓ These files are in `.gitignore` (won't be committed)  
✗ Keep your credentials safe — rotate them periodically  
✗ Never share these files or commit them publicly
