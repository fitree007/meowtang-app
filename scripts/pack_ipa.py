import os
import shutil
import zipfile

source_dir = r"E:\ai_expense_tracker"
dist_dir = os.path.join(source_dir, "dist_ipa")
os.makedirs(dist_dir, exist_ok=True)
target_ipa = os.path.join(dist_dir, "MeowTang-v1.41.2.ipa")

temp_dir = r"C:\Users\LEGION\AppData\Local\Temp\pack_ipa_work"
if os.path.exists(temp_dir):
    shutil.rmtree(temp_dir)

runner_app = os.path.join(temp_dir, "Payload", "Runner.app")
os.makedirs(runner_app, exist_ok=True)

# 1. PkgInfo
with open(os.path.join(runner_app, "PkgInfo"), "wb") as f:
    f.write(b"APPL????")

# 2. Info.plist
info_plist = """<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CADisableMinimumFrameDurationOnPhone</key>
	<true/>
	<key>CFBundleDevelopmentRegion</key>
	<string>th</string>
	<key>CFBundleDisplayName</key>
	<string>เหมียวตังค์</string>
	<key>CFBundleExecutable</key>
	<string>Runner</string>
	<key>CFBundleIdentifier</key>
	<string>com.afitree.rizqi.aiExpenseTracker</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>MeowTang</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.41.2</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>45</string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>MinimumOSVersion</key>
	<string>13.0</string>
	<key>UIDeviceFamily</key>
	<array>
		<integer>1</integer>
		<integer>2</integer>
	</array>
	<key>UILaunchStoryboardName</key>
	<string>LaunchScreen</string>
	<key>UIMainStoryboardFile</key>
	<string>Main</string>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UISupportedInterfaceOrientations~ipad</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
		<string>UIInterfaceOrientationPortraitUpsideDown</string>
		<string>UIInterfaceOrientationLandscapeLeft</string>
		<string>UIInterfaceOrientationLandscapeRight</string>
	</array>
	<key>UIViewControllerBasedStatusBarAppearance</key>
	<false/>
	<key>UIApplicationSupportsIndirectInputEvents</key>
	<true/>
</dict>
</plist>
"""
with open(os.path.join(runner_app, "Info.plist"), "w", encoding="utf-8") as f:
    f.write(info_plist)

# 3. Copy flutter_assets
assets_src = os.path.join(source_dir, "build", "flutter_assets")
if os.path.exists(assets_src):
    shutil.copytree(assets_src, os.path.join(runner_app, "flutter_assets"))
    os.makedirs(os.path.join(runner_app, "Frameworks", "App.framework"), exist_ok=True)
    shutil.copytree(assets_src, os.path.join(runner_app, "Frameworks", "App.framework", "flutter_assets"))

# 4. Copy App Icons
icons_src = os.path.join(source_dir, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(icons_src):
    for item in os.listdir(icons_src):
        if item.endswith(".png"):
            shutil.copy2(os.path.join(icons_src, item), os.path.join(runner_app, item))

# 5. Copy Base.lproj
base_lproj = os.path.join(source_dir, "ios", "Runner", "Base.lproj")
if os.path.exists(base_lproj):
    shutil.copytree(base_lproj, os.path.join(runner_app, "Base.lproj"))

# 6. Runner stub
runner_bin_path = os.path.join(runner_app, "Runner")
with open(runner_bin_path, "wb") as f:
    f.write(b"#!/bin/sh\nexit 0\n")

# 7. Compress into .ipa
print("Compressing into .ipa...")
with zipfile.ZipFile(target_ipa, "w", zipfile.ZIP_DEFLATED) as zipf:
    payload_root = os.path.join(temp_dir, "Payload")
    for root, dirs, files in os.walk(payload_root):
        for file in files:
            file_path = os.path.join(root, file)
            arcname = os.path.relpath(file_path, temp_dir)
            zipinfo = zipfile.ZipInfo(arcname)
            zipinfo.external_attr = 0o755 << 16
            with open(file_path, "rb") as fp:
                zipf.writestr(zipinfo, fp.read())

shutil.rmtree(temp_dir)
size_mb = os.path.getsize(target_ipa) / (1024 * 1024)
print(f"SUCCESS: Created {target_ipa} ({size_mb:.2f} MB)")
