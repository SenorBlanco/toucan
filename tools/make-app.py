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
import shutil
import subprocess
import sys
import tempfile

argparser = argparse.ArgumentParser(description="Create an App")
argparser.add_argument('--target-name')
argparser.add_argument('--target-os')
argparser.add_argument('--out-dir')
args = vars(argparser.parse_args())

target_name = args['target_name']
target_os = args['target_os']
out_dir = os.path.abspath(args['out_dir'])

info_plist = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>''' + target_name + '''</string>
    <key>CFBundleSignature</key>
    <string>TUCN</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleIdentifier</key>
    <string>org.toucanlang.''' + target_name + '''</string>
    <key>CFBundleDisplayName</key>
    <string>''' + target_name + '''</string>
    <key>CFBundleName</key>
    <string>''' + target_name + '''y</string>
</dict>
</plist>
'''

dylibs = [
  "libdawn_native.dylib",
  "libdawn_platform.dylib",
  "libdawn_proc.dylib",
  "libwebgpu_dawn.dylib",
]
source_path = out_dir + "/"
dest_app_path = source_path + target_name + ".app/"
dest_contents_path = dest_app_path + "Contents/"
dest_os_path = dest_contents_path
if target_os == "mac":
  dest_os_path += "MacOS/"

if os.path.exists(dest_app_path):
  shutil.rmtree(dest_app_path)
os.makedirs(dest_os_path)

for dylib in dylibs:
  source_lib = source_path + dylib
  dest_lib = dest_os_path + dylib
  os.symlink(source_lib, dest_lib)

shutil.copy2(source_path + target_name, dest_os_path + target_name)

info_plist_file = dest_contents_path + "Info.plist"
with open(info_plist_file, "w") as f:
  f.write(info_plist)
  f.close()
