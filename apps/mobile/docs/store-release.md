# Store release checklist

Prod artifacts: `./scripts/build-prod.sh` (requires Android upload keystore).

## One-time setup

1. **Android signing** — use the **original** upload keystore registered in Play Console (Setup → App signing). Do not run `setup-android-signing.sh` for an existing listing; it creates a new key Play will reject. Point `ANDROID_KEYSTORE_*` in `.env.release` (or replace `~/.chisto/android-signing.env`) at that `.jks` / `.keystore`. Set `PLAY_EXPECTED_UPLOAD_SHA1` in `.env.release` so `build-prod.sh` fails before upload if the cert is wrong.
2. **Sentry** — copy `.env.release.example` → `.env.release`, set `SENTRY_DSN`.
3. **Deep links** — deploy `apps/landing` so `https://chisto.mk/.well-known/*` is live.
4. After **Play App Signing** enrollment, append the Play *app signing* SHA-256 to `apps/landing/public/.well-known/assetlinks.json`.

## Pre-upload QA

```sh
./scripts/release-qa.sh
./scripts/build-prod.sh
```

Smoke-test the IPA (TestFlight) and AAB (Play internal track) on physical devices against `https://api.chisto.mk`.

**Android media permissions (Play policy):** `./scripts/release-qa.sh` runs `tool/check_android_play_media_permissions.dart`, which merges the release manifest and fails if `READ_MEDIA_*` or `READ_EXTERNAL_STORAGE` appear. Before production upload, smoke-test on Android 13+:

| Flow | Action |
|------|--------|
| Pollution report | Camera + choose from library |
| Profile avatar | Selfie + gallery |
| Event chat | Attach photo, video, document |
| Chat attachment | Open a non-PDF document |

## Upload

| Platform | Artifact | Console |
|----------|----------|---------|
| iOS | `build/ios/ipa/*.ipa` | [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) → App Store Connect |
| Android | `build/app/outputs/bundle/release/app-release.aab` | Play Console → Production (or internal first) |

**Review notes:** provide a demo phone/email for OTP, explain permissions, point to Profile → Delete account.

### Google Play resubmission (photo/video permissions fix)

1. **Publishing overview** → resolve the Photo and Video Permissions policy issue.
2. **Release** → internal testing first (recommended), then production → create new release.
3. Upload `app-release.aab` with a **new versionCode** (must be higher than the rejected build).
4. **Deactivate** older builds on all active tracks that still declare `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`.
5. **App content → Sensitive app permissions / Photo and video permissions:** declare no broad photo/video library access; one-time attachments use the system picker.
6. **Data safety:** align declarations with the manifest (no persistent photo-library read permission).
7. Release notes example: “Removed unnecessary media storage permissions; photo/video selection uses the Android system picker.”
8. Submit for review.

## Verify deep links

```sh
curl -fsSL https://chisto.mk/.well-known/apple-app-site-association | grep applinks
curl -fsSL https://chisto.mk/.well-known/assetlinks.json | grep android_app
```

Or trigger the **Verify universal links** GitHub Actions workflow.
