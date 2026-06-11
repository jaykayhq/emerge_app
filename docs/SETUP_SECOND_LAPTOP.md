# Emerge App: Transfer & Setup on a Second Laptop

This guide explains how to configure and build the **Emerge App** on a second developer laptop, ensuring that all credentials, secret keys, and configuration files are correctly aligned for building signed release App Bundles (`.aab`) for the Google Play Store.

---

## Overview of Local Untracked Files

Because sensitive keys and configuration files are kept out of version control (as defined in [.gitignore](file:///c:/Users/JOSHUA/Downloads/emerge_app/.gitignore)), they will not automatically sync when you pull the repository from GitHub. You must transfer them manually once.

Here is the checklist of files to copy:

| File Name | Current Source Path | Destination Path on Second Laptop |
| :--- | :--- | :--- |
| **`emerge-release.jks`** (Keystore) | `C:\Users\JOSHUA\emerge-release.jks` | `android/app/emerge-release.jks` |
| **`key.properties`** (Key config) | `android/key.properties` | `android/key.properties` |
| **`google-services.json`** (Firebase config) | `android/app/google-services.json` | `android/app/google-services.json` |
| **`firebase_options.dart`** (Firebase init) | `lib/firebase_options.dart` | `lib/firebase_options.dart` |
| **`.env`** (Environment variables) | `.env` (Project root) | `.env` (Project root) |

---

## Setup Instructions (One-Time)

### 1. Copy the Files to the Second Laptop
Use a secure USB drive, local network share, or private sharing method to copy the five files listed above from the main machine to the second laptop.

### 2. Place the Keystore in the Project
Place the `emerge-release.jks` keystore file directly inside the `android/app/` folder of your project on the second laptop. 
> [!NOTE]
> Putting it inside the `android/app/` directory is safe because the file extension `*.jks` is ignored by Git, meaning it will never be accidentally committed to GitHub.

### 3. Configure `android/key.properties`
To make the project build seamlessly across both laptops without needing to modify absolute file paths, we use a **relative path** in the configuration:

Open the `android/key.properties` file on the second laptop and verify/update its contents to look like this:

```properties
storePassword=emerge123
keyPassword=emerge123
keyAlias=emerge
storeFile=../app/emerge-release.jks
```

*Note: The relative path `../app/emerge-release.jks` resolves correctly on all Windows, macOS, and Linux laptops, relative to the `android/` directory.*

### 4. Restore the Other Configuration Files
Place the other configuration files in their respective folders:
* Put `google-services.json` in `android/app/`.
* Put `firebase_options.dart` in `lib/`.
* Put `.env` in the root folder of the project.

---

## How to Build the App Bundle

Once the local files are placed in their proper locations, open a terminal in the project root folder on the second laptop and run the following command sequence:

```bash
# 1. Clean build artifacts and cached paths from the other system
flutter clean

# 2. Re-download and sync dependency packages
flutter pub get

# 3. Generate the signed release App Bundle (.aab)
flutter build appbundle --release
```

The successfully built bundle will be located at:
`[project-root]/build/app/outputs/bundle/release/app.aab`

You can upload this file directly to the **Google Play Console** to release app updates.
