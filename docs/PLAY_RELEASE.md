# Google Play release guide

This project is configured to build a signed Android App Bundle (AAB) and
upload version tags to the Google Play **internal testing** track once Play API
credentials are configured. It does not publish to production. The Play Console
app exists, but policy declarations, store assets, Play App Signing enrollment,
and the first app upload are still outstanding.

## Current technical readiness

- Android package/application ID: `com.onehand.onehand_launcher`. The
  **One-Handed Launcher** app has been created in Play Console; do not create
  another app or change this ID.
- Play Console app setup has started. The privacy-policy URL
  (`https://amargm.github.io/onehand-launcher/`) and the "no ads" declaration
  are saved. Paid distribution was selected, but a merchant account is still
  required before a paid price can be configured.
- The upload key is stored locally at
  `C:\Users\mugal\OneHandLauncherSigning\onehand-upload.jks`; its password
  files are DPAPI-encrypted for the Windows user. The public certificate is
  `C:\Users\mugal\OneHandLauncherSigning\onehand-upload-certificate.pem`.
  Register this certificate in Play Console's Play App Signing setup before
  uploading an AAB. The private key and password files must never be committed
  or sent in chat.
- The `play-internal` GitHub environment already contains the four
  `ANDROID_UPLOAD_*` signing secrets. `PLAY_SERVICE_ACCOUNT_JSON` is not yet
  configured, so the tagged workflow cannot upload to Play until a suitable
  Google Cloud project, Play Developer API service account, and Play Console
  access are configured.
- The Android workflow has a manual **Build signed AAB for manual Play upload**
  path on `main`. It uses the permanent upload key and uploads only the AAB
  artifact; it does not require Play API credentials and does not publish to a
  testing track.
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

## Before completing the public listing

### Privacy, permissions, and Data safety

Review the actual release and all bundled SDKs before completing Data safety.
The current app source shows these data flows:

| Feature or permission | Current behavior to account for |
| --- | --- |
| `QUERY_ALL_PACKAGES` | The launcher queries installed launchable apps and media apps to populate launcher UI. Google Play requires a declaration and review for broad package visibility. Describe the launcher as the core use; approval is not guaranteed. |
| Coarse location | Optional holiday country detection obtains a low-accuracy location and sends latitude/longitude to Nominatim for country-level reverse geocoding. The resulting country code is cached locally. A user can choose a country manually if location is declined. |
| Holiday lookup | The selected country code and year are sent to Nager.Date and OpenHolidays. |
| Wallpaper picker | Visible thumbnail requests go to Unsplash or Pexels; preview/apply requests the selected full-size image. |
| Fonts | The app uses `google_fonts` without bundled font assets; missing font files may be requested automatically from Google Fonts while rendering the UI. |
| Local preferences | Settings, folders, recent app package IDs, widget selections, calendar-related data, and cached country/holiday values use local preferences. |
| Wallpaper setting | The user-selected image is downloaded and passed to Android's wallpaper service. |
| Support and feedback | The app opens the device email app; a message and any details in it are sent only if the user chooses to send it. |

The resolved app dependencies do not include an advertising, analytics, or
crash-reporting SDK. Online font, wallpaper, holiday, and reverse-geocoding
requests do disclose ordinary connection data (including an IP address) to
their respective providers; automatic country detection additionally sends
approximate coordinates to Nominatim after the user accepts an in-app
disclosure and grants Android location permission. Installed-app information
is accessed for launcher functionality and kept on-device. These behaviors
are described in the privacy policy; complete Play's Data safety answers to
match the final packaged release and SDK behavior, not simply the developer's
lack of a backend.

The app's privacy link points to
`https://amargm.github.io/onehand-launcher/`. The policy page source
is `docs/privacy/index.html`; a GitHub Actions workflow deploys the contents
of `docs/privacy/` to the root of the GitHub Pages site when changes are
pushed to `main`. Enable GitHub Pages with
**Settings → Pages → Build and deployment → Source: GitHub Actions**, push
the change to `main`, and wait for the Pages deployment workflow to succeed.
Then open the URL in a private browser and confirm it loads over HTTPS before
using it in Play Console. The policy and in-app support link use
`mugaliamar@gmail.com`, the developer account email currently shown in Play
Console. This address appears publicly in the policy and app; keep the
mailbox monitored for privacy and support requests.

Remaining Play Console setup:

- The `QUERY_ALL_PACKAGES` permission declaration and any requested supporting
  explanation/screenshots.
- Data safety form, content rating, target audience, app category, public
  contact details, and app-access declaration. The privacy-policy URL and ads
  declaration have already been saved; verify them against the release before
  submitting changes for review.
- Create the merchant account and configure the paid price in Play Console.
  Payout and tax details are account-owner information and must be supplied by
  the developer.
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
  localization. A factual copy draft is provided below; review it against the
  final release before publishing. **Personalization** is a likely category
  for a home-screen launcher; choose the closest category actually offered by
  Play Console.
- 512 x 512 store icon, 1024 x 500 feature graphic, and current phone
  screenshots (plus tablet/other device screenshots if you support those
  device types).
- A closed/internal tester list and tester instructions as appropriate.

Check the current [Play Console listing requirements](https://support.google.com/googleplay/android-developer/answer/9866151)
for exact formats and limits.

#### Listing copy draft

**App name:** One-Handed Launcher

**Short description (66/80 characters):**

A calm, ergonomic Android home screen designed for one-handed use.

**Full description:**

Make your Android home screen easier to use with One-Handed Launcher, a
minimalist launcher designed around comfortable reach and a calm, dark visual
style.

Keep the apps you use most close at hand. Organize apps into folders, search
for apps, and arrange your home screen to suit the way you use your phone.

Personalize your setup with appearance options and wallpapers. Add widgets from
compatible apps, and explore the optional public-holiday calendar with manual
country selection or automatic country detection.

One-Handed Launcher is a home-screen replacement. Choose it as your default
Home app in Android settings to use it. Some features, including widgets and
automatic country detection, depend on Android permissions and compatible
apps. Automatic country detection uses approximate location to look up a
country; you can deny location permission and choose a country manually.

Requires Android 8.0 or later.

## Signing and credential setup

Google Play App Signing should hold the **app signing key**. The key used in
this repository/CI is the separate **upload key**. Never commit the upload
keystore, its passwords, or the Play service-account JSON.

1. The Play Console app already exists with package ID
   `com.onehand.onehand_launcher`. Enroll it in Play App Signing and register
   the existing upload certificate
   `C:\Users\mugal\OneHandLauncherSigning\onehand-upload-certificate.pem`.
2. The upload key has already been generated locally. Keep at least two
   encrypted offline backups of the keystore, and store passwords separately.
   If replacing or resetting the upload key, generate a new key using Java's
   `keytool` from a secure directory outside the repository; `keytool` prompts
   for passwords:

   ```powershell
   keytool -genkeypair -v `
     -keystore C:\secure\onehand-upload.jks `
     -storetype JKS `
     -keyalg RSA `
     -keysize 2048 `
     -validity 10000 `
     -alias onehand-upload
   ```

3. If rotating the upload key, export its certificate and register the new
   certificate in Play Console when prompted:

   ```powershell
   keytool -exportcert -rfc `
     -keystore C:\secure\onehand-upload.jks `
     -alias onehand-upload `
     -file C:\secure\onehand-upload-certificate.pem
   ```

4. The repository's Android `.gitignore` excludes
   `.jks`/`.keystore` files, but do not rely on ignore rules as a secret
   management system. If an upload key is lost, follow Google's upload-key
   reset procedure; do not replace the Play app-signing key.
5. The GitHub Actions environment `play-internal` and its four signing secrets
   are already configured. The following table shows the required
   **environment secrets**; only `PLAY_SERVICE_ACCOUNT_JSON` remains to be
   added:

   | Secret | Value |
   | --- | --- |
   | `ANDROID_UPLOAD_KEYSTORE_BASE64` | Configured |
   | `ANDROID_UPLOAD_KEYSTORE_PASSWORD` | Configured |
   | `ANDROID_UPLOAD_KEY_ALIAS` | Configured (`onehand-upload`) |
   | `ANDROID_UPLOAD_KEY_PASSWORD` | Configured |
   | `PLAY_SERVICE_ACCOUNT_JSON` | Pending: full service-account JSON, as plain text |

   To copy the keystore's base64 value to the Windows clipboard without
   printing it:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\secure\onehand-upload.jks")) | Set-Clipboard
   ```

   This is only needed when initially configuring or rotating the existing
   signing secret. Paste the value directly into the GitHub environment secret,
   then clear the clipboard. Keep the source keystore and offline backups.
6. In a suitable Google Cloud project, enable the Google Play Android
   Developer API and create a service account. Invite its email in Play Console
   with only the app-level permissions needed to manage testing releases. Add
   its JSON key directly to `PLAY_SERVICE_ACCOUNT_JSON`; never store it in the
   repository or as a workflow artifact. No Play service-account JSON is
   currently available. Do not attach a billing account to an unrelated Cloud
   project just to complete this step.
7. Configure `play-internal` with required reviewers and restrict deployments
   to release tags if the repository plan supports those protections. The
   workflow grants Play credentials only to tagged release jobs, but anyone
   able to push a qualifying tag can otherwise request a deployment.

The workflow pins the Play upload action to a specific upstream commit. Review
that action and its updates before changing the pin.

## First upload and subsequent releases

The Play upload API requires the package to exist in Play Console, so perform
the initial upload manually before relying on automated uploads:

1. The app already exists in Play Console. Register the upload certificate and
   finish Play App Signing setup before uploading.
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
3. Complete any required Play Console setup for the internal test. To create
   the initial bundle without Play API credentials, run **Android CI and Play
   internal release → Run workflow** on `main`. The workflow validates the
   configured upload-signing secrets and exposes `onehand-signed-aab` as a
   downloadable artifact. Upload that AAB manually only after registering the
   matching upload certificate and completing Play App Signing setup. This
   manual workflow does not publish to a testing track. Before relying on the
   tagged workflow, configure the pending Play service-account secret and
   verify that the account can upload to this app.
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
