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

## Upload

| Platform | Artifact | Console |
|----------|----------|---------|
| iOS | `build/ios/ipa/*.ipa` | [Transporter](https://apps.apple.com/us/app/transporter/id1450874784) → App Store Connect |
| Android | `build/app/outputs/bundle/release/app-release.aab` | Play Console → Production (or internal first) |

**Review notes:** provide a demo phone/email for OTP, explain permissions, point to Profile → Delete account.

## Verify deep links

```sh
curl -fsSL https://chisto.mk/.well-known/apple-app-site-association | grep applinks
curl -fsSL https://chisto.mk/.well-known/assetlinks.json | grep android_app
```

Or trigger the **Verify universal links** GitHub Actions workflow.
