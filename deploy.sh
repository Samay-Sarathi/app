#!/usr/bin/env bash
set -e

echo "Building release APK..."
/home/mohit/fvm/versions/3.38.9/bin/flutter build apk --release

echo "Deploying to server..."
scp -i ~/.ssh/id_lifeline build/app/outputs/flutter-apk/app-release.apk root@142.93.210.30:/var/www/samaysarathi/samaysarathi.apk

echo "Done! APK live at https://samaysarathi.in/samaysarathi.apk"
