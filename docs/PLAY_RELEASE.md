# Google Play release guide

This project is configured to build a signed Android App Bundle (AAB) and
upload version tags to the Google Play **internal testing** track. It does not
publish to production. Play Console account setup, policy declarations, store
assets, and the initial app upload still require the account owner.

## Current technical readiness

- Android package/application ID: `com.onehand.onehand_launcher`. Treat this
  as permanent once the app is created in Play Console, and confirm it is
  available in the account before creating the listing.
- Minimum Android version: API 26 (Android 8.0).
- Compile and target SDK: API 36. Google Play requires API 36 for new apps and
  updates from August 31, 2026; confirm the current requirement before each
  release in the [target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878).
- The main manifest now declares `INTERNET`. Without it the release build could
  not load fonts, wallpapers, or holiday data even though debug/profile builds
  had network access.
- Release signing now requires the configured upload keystore and all signing
  values; a release build does not silently fall back to debug signing.
- The workflow runs analysis, tests, and a debug build for pushes and pull
  requests. A `vMAJOR.MINOR.PATCH` tag builds a signed AAB and completes an
  internal-track release after the verification job passes.
- The existing test file is only a placeholder smoke test. Passing `flutter
  test` is not a substitute for device/launcher acceptance testing.

## Before creating the public listing

### Privacy, permissions, and Data safety

Review the actual release and all bundled SDKs before completing Data safety.
The current app source shows these data flows:

| Feature or permission | Current behavior to account for |
| --- | --- |
| `QUERY_ALL_PACKAGES` | The launcher queries installed launchable apps and media apps to populate launcher UI. Google Play requires a declaration and review for broad package visibility. Describe the launcher as the core use; approval is not guaranteed. |
| Coarse location | Optional holiday country detection obtains a low-accuracy location and sends latitude/longitude to Nominatim for country-level reverse geocoding. The resulting country code is cached locally. A user can choose a country manually if location is declined. |
| Holiday lookup | The selected country code and year are sent to Nager.Date and OpenHolidays. |
| Wallpaper picker | Image requests go to Unsplash's image CDN. |
| Fonts | The app uses `google_fonts`; verify whether Google Fonts requests occur at runtime for the packaged versions and disclose any resulting external data flow. |
| Local preferences | Settings, folders, calendar-related data, and cached country/holiday values use local preferences. |
| Wallpaper setting | The user-selected image is downloaded and passed to Android's wallpaper service. |

The listed dependencies do not include an analytics, advertising, or crash
reporting SDK, but inspect the complete resolved dependency tree and each SDK's
data practices before asserting that no data is collected or shared. Installed
app inventory and location are sensitive data for Play policy purposes.
Provide any required prominent in-app disclosure/consent before the relevant
collection or transfer, and keep the privacy policy and Play Data safety form
consistent with the actual binary.

The app's privacy link points to
`https://amargm.github.io/onehand-launcher/`. The policy page source
is `docs/privacy/index.html`; a GitHub Actions workflow deploys the contents
of `docs/privacy/` to the root of the GitHub Pages site when changes are
pushed to `main`. Enable GitHub Pages with
**Settings → Pages → Build and deployment → Source: GitHub Actions**, push
the change to `main`, and wait for the Pages deployment workflow to succeed.
Then open the URL in a private browser and confirm it loads over HTTPS before
using it in Play Console. The policy uses the app's existing
`support@onehandlauncher.app` contact; verify that this mailbox is active and
monitored and that the policy matches the actual release and dependencies
before publication.

Complete in Play Console:

- The `QUERY_ALL_PACKAGES` permission declaration and any requested supporting
  explanation/screenshots.
- Data safety form, privacy-policy URL, content rating, target audience, ads
  declaration, app category, contact details, and app-access declaration.
- Confirm the account's testing requirements. Newly created personal
  developer accounts may need a qualifying closed test before production
  access; internal testing alone may not satisfy that requirement.
- Check the app's target API requirement and Play Console warnings again at
  submission time.

### Listing and test assets

Prepare the listing in Play Console; no listing text or marketing assets are
submitted by CI. The repository contains Android launcher mipmap icons but
does not include a complete Play listing asset set. Prepare and verify:

- App name, short and full descriptions, category, contact details, and
  localization.
- 512 x 512 store icon, 1024 x 500 feature graphic, and current phone
  screenshots (plus tablet/other device screenshots if you support those
  device types).
- A closed/internal tester list and tester instructions as appropriate.

Check the current [Play Console listing requirements](https://support.google.com/googleplay/android-developer/answer/9866151)
for exact formats and limits.

## Signing and credential setup

Google Play App Signing should hold the **app signing key**. The key used in
this repository/CI is the separate **upload key**. Never commit the upload
keystore, its passwords, or the Play service-account JSON.

1. Create a new app in Play Console using package ID
   `com.onehand.onehand_launcher` and enroll in Play App Signing.
2. Generate an upload key using Java's `keytool`. Run this from a secure
   directory outside the repository; `keytool` prompts for passwords:

   ```powershell
   keytool -genkeypair -v `
     -keystore C:\secure\onehand-upload.jks `
     -storetype JKS `
     -keyalg RSA `
     -keysize 2048 `
     -validity 10000 `
     -alias onehand-upload
   ```

3. Export the upload certificate and register it in Play Console when
   prompted:

   ```powershell
   keytool -exportcert -rfc `
     -keystore C:\secure\onehand-upload.jks `
     -alias onehand-upload `
     -file C:\secure\onehand-upload-certificate.pem
   ```

4. Keep at least two encrypted offline backups of the keystore and store
   passwords separately. The repository's Android `.gitignore` excludes
   `.jks`/`.keystore` files, but do not rely on ignore rules as a secret
   management system. If an upload key is lost, follow Google's upload-key
   reset procedure; do not replace the Play app-signing key.
5. Create a GitHub Actions environment named `play-internal`. Add these
   **environment secrets** with exact names:

   | Secret | Value |
   | --- | --- |
   | `ANDROID_UPLOAD_KEYSTORE_BASE64` | Base64 of the upload `.jks` file |
   | `ANDROID_UPLOAD_KEYSTORE_PASSWORD` | Keystore password |
   | `ANDROID_UPLOAD_KEY_ALIAS` | `onehand-upload` (or the alias actually created) |
   | `ANDROID_UPLOAD_KEY_PASSWORD` | Key password |
   | `PLAY_SERVICE_ACCOUNT_JSON` | Full service-account JSON, as plain text |

   To copy the keystore's base64 value to the Windows clipboard without
   printing it:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secure\onehand-upload.jks")) | Set-Clipboard
   ```

   Paste it directly into the GitHub environment secret, then clear the
   clipboard. Keep the source keystore and offline backups.
6. In the Google Cloud project linked to Play Console, enable the Google Play
   Android Developer API and create a service account. Invite its email in
   Play Console with only the app-level permissions needed to manage testing
   releases. Put the JSON key in `PLAY_SERVICE_ACCOUNT_JSON`; never store it in
   the repository or as a workflow artifact.
7. Configure `play-internal` with required reviewers and restrict deployments
   to release tags if the repository plan supports those protections. The
   workflow grants Play credentials only to tagged release jobs, but anyone
   able to push a qualifying tag can otherwise request a deployment.

The workflow pins the Play upload action to a specific upstream commit. Review
that action and its updates before changing the pin.

## First upload and subsequent releases

The Play upload API requires the package to exist in Play Console, so perform
the initial upload manually before relying on automated uploads:

1. Complete the app creation and Play App Signing setup above.
2. Set the release environment variables locally (do not put passwords in
   source files or commit them), build the initial signed AAB, and upload it
   through Play Console. This PowerShell example prompts for passwords without
   echoing them or adding them to command history; the Gradle process still
   needs them temporarily in its environment:

   ```powershell
   function Set-ProcessSecret($Name, $PromptText) {
     $secure = Read-Host $PromptText -AsSecureString
     $pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
     try {
       [Environment]::SetEnvironmentVariable(
         $Name,
         [Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer),
         "Process"
       )
     } finally {
       [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer)
       $secure.Dispose()
     }
   }

   $env:ANDROID_UPLOAD_KEYSTORE_PATH = "C:\secure\onehand-upload.jks"
   $env:ANDROID_UPLOAD_KEY_ALIAS = "onehand-upload"
   Set-ProcessSecret "ANDROID_UPLOAD_KEYSTORE_PASSWORD" "Upload keystore password"
   Set-ProcessSecret "ANDROID_UPLOAD_KEY_PASSWORD" "Upload key password"
   flutter pub get
   flutter build appbundle --release --build-name=1.0.0 --build-number=1000000

   Remove-Item Env:ANDROID_UPLOAD_KEYSTORE_PATH
   Remove-Item Env:ANDROID_UPLOAD_KEY_ALIAS
   Remove-Item Env:ANDROID_UPLOAD_KEYSTORE_PASSWORD
   Remove-Item Env:ANDROID_UPLOAD_KEY_PASSWORD
   ```

   The Gradle build requires `ANDROID_UPLOAD_KEYSTORE_PATH`,
   `ANDROID_UPLOAD_KEYSTORE_PASSWORD`, `ANDROID_UPLOAD_KEY_ALIAS`, and
   `ANDROID_UPLOAD_KEY_PASSWORD` in its process environment.
3. Complete any required Play Console setup for the internal test. Add the
   five GitHub environment secrets only after the initial package/upload
   bootstrap is complete.
4. For each update, increase the semantic version and set `pubspec.yaml` to
   `version: MAJOR.MINOR.PATCH+VERSION_CODE`. The version code is
   `MAJOR * 1,000,000 + MINOR * 1,000 + PATCH`. For example, `1.0.1` uses
   `1.0.1+1000001`. Keep minor and patch components at or below 999 and major
   at or below 2099. The workflow verifies that the tag and `pubspec.yaml`
   agree before building.
5. Commit the version update, create a new immutable annotated tag matching
   the version (for example, `v1.0.1`), and push the commit and tag. The tag
   runs analysis/tests/debug build, then uploads the signed AAB to the
   **internal** track. Do not reuse or move a published version tag.
6. Review the uploaded release and tester experience in Play Console. Promote
   a tested release to closed/open testing or production manually; this
   workflow never targets those tracks.

Before promoting, test installation and update on supported Android devices,
including Android 16: first-run/default-home selection, launcher/app drawer,
widget binding consent, denied location and manual country fallback, wallpaper
downloads, and upgrade from the previous Play build without losing settings.
Verify the uploaded artifact and merged manifest in Play Console/App Bundle
Explorer.
