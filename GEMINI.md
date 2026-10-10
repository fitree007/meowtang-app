# Standing Workflow Rules for MeowTang Project

## Project Location (ตำแหน่งโปรเจกต์ - มีชุดเดียว)
- The ONLY project folder is `E:\ai_expense_tracker` (git repo). Everything for MeowTang lives here; nothing needs syncing with `E:\สร้างแอพ apk`.
- Always run `flutter`, `gradle`, `git` and scripts with the working directory `E:\ai_expense_tracker` (ASCII path). Running Flutter tools from a Thai path can crash `flutter analyze` or break builds.
- Local-only folders (gitignored, never committed):
  - `releases\` — latest Creator APK, `releases\playstore\` (Play Store APK/AAB, screenshots, release notes), `releases\google_play_submission_kit\`, `releases\old\` (previous APK/AAB).
  - `design\app_logos\` — logo and mascot source artwork.
- `E:\สร้างแอพ apk\ไม่จำเป็น` contains old files the user will delete. Do not use or modify anything inside it.

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
  - Update `version: X.Y.Z+build` in `pubspec.yaml` (in `E:\ai_expense_tracker`).
  - Update `static const String appVersion = 'X.Y.Z';` in `lib/state/expense_controller.dart`.

## 4. Build Release APK (ทำเป็นไฟล์ apk)
- Build release APK (run in `E:\ai_expense_tracker`):
  `flutter build apk --release --android-skip-build-dependency-validation`
- Move previous APKs/AABs into `releases\old\`. Do NOT create new `archive_old_apks` folders.
- Copy the newly built APK to:
  - `releases\MeowTang-Creator-vX.Y.Z.apk`
  - `releases\playstore\MeowTang-PlayStore-vX.Y.Z.apk`
- Commit to git once, in `E:\ai_expense_tracker`.
- Push to GitHub (`git push origin main` and deploy web to `gh-pages` using `powershell -ExecutionPolicy Bypass -File scripts/deploy_web.ps1` in `E:\ai_expense_tracker`) so that GitHub Pages (`https://fitree007.github.io/meowtang-app/`) is always up-to-date automatically.
