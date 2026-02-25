# Apple Sign-In Configuration (Pending Apple Developer Account)

## ✅ COMPLETED (Have These)
- Firebase Project ID: `infinity-notes-xxxxxx`
- OAuth Redirect URI: `https://infinity-notes-xxxxxx.firebaseapp.com/__/auth/handler`
- Bundle ID: `com.ehv.infinityNotes`

## ❌ PENDING (Need Apple Developer Account)

### Service ID (for code clientId)
**What:** Apple Service ID identifier
**Format:** `com.ehv.infinityNotes.firebase`
**Where to get:** developer.apple.com/account/resources/identifiers/list/serviceId
**Used in:** `sign_in_with_apple.dart` line 21

### Team ID (for Firebase Console)
**What:** 10-character Apple Team ID
**Format:** Example: `A1B2C3D4E5`
**Where to get:** developer.apple.com/account (top right corner)
**Used in:** Firebase Console → Authentication → Apple provider

### Key ID (for Firebase Console)
**What:** 10-character Authentication Key ID
**Format:** Example: `X9Y8Z7W6V5`
**Where to get:** developer.apple.com/account/resources/authkeys/list
**Used in:** Firebase Console → Authentication → Apple provider

### Private Key (for Firebase Console)
**What:** Contents of .p8 key file
**Format:** Multi-line text starting with `-----BEGIN PRIVATE KEY-----`
**Where to get:** Download when creating Auth Key (CANNOT re-download)
**Used in:** Firebase Console → Authentication → Apple provider

## 🔧 SETUP STEPS (When You Get Apple Developer Access)

1. Create Service ID: `com.ehv.infinityNotes.firebase`
2. Configure domains: `infinity-notes-xxxxxx.firebaseapp.com`
3. Configure return URL: `https://infinity-notes-xxxxxx.firebaseapp.com/__/auth/handler`
4. Create Authentication Key → Download .p8 file
5. Update Firebase Console with Team ID, Key ID, Private Key
6. Update code with Service ID (replace placeholder)

