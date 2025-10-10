#!/usr/bin/env python3

# Copyright 2025 The Toucan Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import os
import plistlib
import shutil
import subprocess
import tempfile

argparser = argparse.ArgumentParser(description="Create an App")
argparser.add_argument('--target-name')
argparser.add_argument('--target-os')
argparser.add_argument('--mobile-provision')
argparser.add_argument('--team-identifier')
argparser.add_argument('--codesign-identity')
args = vars(argparser.parse_args())

target_name = args['target_name']
target_os = args['target_os']

info_plist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>''' + target_name + '''</string>
    <key>CFBundleIdentifier</key>
    <string>org.toucanlang.sample.''' + target_name + '''</string>
    <key>CFBundleName</key>
    <string>''' + target_name + '''</string>
</dict>
</plist>
'''

dest_app_path = target_name + ".app/"
if target_os == "mac":
  dest_contents_path = dest_app_path + "Contents/"
  dest_os_path = dest_contents_path + "MacOS/"
else:
  dest_os_path = dest_contents_path = dest_app_path

if os.path.exists(dest_app_path):
  shutil.rmtree(dest_app_path)
os.makedirs(dest_os_path)

if target_os == "mac":
  dylibs = [
    "libdawn_native.dylib",
    "libdawn_platform.dylib",
    "libdawn_proc.dylib",
    "libwebgpu_dawn.dylib",
  ]
  for dylib in dylibs:
    shutil.copy2(dylib, dest_os_path + dylib)

shutil.copy2(target_name, dest_os_path + target_name)

info_plist_file = dest_contents_path + "Info.plist"
with open(info_plist_file, "w") as f:
  f.write(info_plist)
  f.close()

if target_os == "ios":
  team_identifier = args['team_identifier']
  codesign_identity = args['codesign_identity']
  mobile_provision = os.path.abspath(args['mobile_provision'])
  shutil.copy2(mobile_provision, dest_app_path + '/' + 'embedded.mobileprovision')

  (entitlements_file, entitlements_filename) = tempfile.mkstemp()
  entitlements = dict([
    ('application-identifier', team_identifier + ".org.toucanlang.sample.window"),
    ('com.apple.developer.team-identifier', team_identifier),
  ])

  with open(entitlements_filename, "wb") as fp:
    plistlib.dump(entitlements, fp, fmt=plistlib.FMT_XML)
    fp.close()

  subprocess.check_call(["codesign", "-s", codesign_identity, "--entitlements", entitlements_filename, dest_os_path])
  os.remove(entitlements_filename)
