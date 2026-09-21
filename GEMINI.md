# Standing Workflow Rules for MeowTang Project

Whenever an update or request is received from the user, you MUST strictly follow this 4-step protocol in order:

## 1. Summarize & Ask for Approval First (สรุปสิ่งที่เข้าใจและถามผู้ใช้ก่อนเริ่มทำ)
- Before modifying files or building APKs:
  - Summarize your clear understanding of the user's requirements.
  - Explain the proposed implementation plan and UI/logic details.
  - Ask the user for confirmation/approval before proceeding with execution.
  - Wait for the user's approval before modifying files or building APKs.

## 2. Provide Computer / PC Preview (ทำให้สามารถดูตัวอย่างบนคอมได้ด้วย)
- Enable the user to preview changes directly on their PC/computer:
  - Launch/offer live web preview (`flutter run -d chrome`) or provide an interactive HTML preview artifact / simulator that the user can open and test directly in their browser.

## 3. Version Bumping (อัพเดทเวอร์ชั่น)
- Every release must increment the app version:
  - Update `version: X.Y.Z+build` in `pubspec.yaml` (both main and mirror repos).
  - Update `static const String appVersion = 'X.Y.Z';` in `lib/state/expense_controller.dart` (both repos).

## 4. Build Release APK (ทำเป็นไฟล์ apk)
- Build release APK:
  `flutter build apk --release --android-skip-build-dependency-validation`
- Move previous APKs into `archive_old_apks` in both release directories.
- Copy the newly built APK to:
  - `E:\สร้างแอพ apk\MeowTang-Creator-vX.Y.Z.apk`
  - `E:\สร้างแอพ apk\playstore_release\MeowTang-PlayStore-vX.Y.Z.apk`
- Sync all files and commit to git in both repositories (`E:\ai_expense_tracker` and `E:\สร้างแอพ apk\ai_expense_tracker`).
