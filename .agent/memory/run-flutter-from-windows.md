# Memory: Run Flutter from Windows in WSL environment

## Rule
On WSL, the Linux Flutter SDK at `/mnt/c/src/flutter` is broken (only `.exe` binaries in `bin/cache/dart-sdk/bin/`, no Linux dart binary). Flutter commands must be run via Windows, not via WSL bash directly.

## How to invoke
From a WSL bash shell, run Windows commands via PowerShell:

```bash
powershell.exe -NoProfile -Command "flutter <command>"
```

Or via cmd:

```bash
cmd.exe /c "flutter <command>"
```

Or directly via git bash on Windows if available:

```bash
/mnt/c/Program\ Files/Git/bin/bash.exe -c "cd /mnt/c/Users/HP/Downloads/emerge_app && flutter <command>"
```

## Examples

```bash
# pub get
powershell.exe -NoProfile -Command "flutter pub get"

# codegen
powershell.exe -NoProfile -Command "dart run build_runner build --delete-conflicting-outputs"

# analyze
powershell.exe -NoProfile -Command "flutter analyze"

# test
powershell.exe -NoProfile -Command "flutter test test/path/to/file_test.dart"

# build
powershell.exe -NoProfile -Command "flutter build apk --debug"
```

## What does NOT work from WSL bash
- `flutter` invoked directly — `/mnt/c/src/flutter/bin/dart` is missing on Linux
- `dart` invoked directly — same reason
- `dart analyze`, `flutter analyze` from WSL bash
- `flutter test` from WSL bash

## Detection
Quick check that breaks fast:
```bash
ls /mnt/c/src/flutter/bin/cache/dart-sdk/bin/dart 2>&1
# If "No such file or directory" → use powershell.exe from WSL
```

## Source
This was discovered during the lobby restructure work (June 2026) while debugging
`Error: Unable to 'pub upgrade' flutter tool. Retrying in five seconds...` when
trying to run `flutter analyze` from WSL.
