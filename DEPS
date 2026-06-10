# Copyright 2023 The Toucan Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

vars = {
  'ninja_version': 'version:2@1.11.1.chromium.6',
}

deps = {
  "buildtools"                            : "https://chromium.googlesource.com/chromium/src/buildtools@1267724b67c1e44a778f610ae9dac191f06e2ff4",
  "third_party/abseil-cpp"             : "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp@564023aa53767b5f60b3a556f0a025b7b7e8241e",
  "third_party/getopt"                 : "https://github.com/skeeto/getopt@4e618ef782dc80b2cf0307ea74b68e6a62b025de",
  "third_party/llvm" : "https://github.com/llvm/llvm-project@216e85bdda22ae7eda3f3e04c51d9d6d82e2b617",
  "third_party/dawn" : "https://dawn.googlesource.com/dawn.git@e8fdf6b115d128adc6ad29e91d38d32f60eb91f0",
  "third_party/jinja2" : "https://chromium.googlesource.com/chromium/src/third_party/jinja2@c3027d884967773057bf74b957e3fea87e5df4d7",
  "third_party/libjpeg-turbo" : "https://github.com/libjpeg-turbo/libjpeg-turbo@3b19db4e6e7493a748369974819b4c5fa84c7614",
  "third_party/libultrahdr" : "https://github.com/google/libultrahdr.git@d52a0d13814ca399fc8a07e23de1d2c63f0e8404",
  "third_party/markupsafe": "https://chromium.googlesource.com/chromium/src/third_party/markupsafe@4256084ae14175d38a3ff7d739dca83ae49ccec6",
  "third_party/egl-registry" : "https://github.com/KhronosGroup/EGL-Registry@7dea2ed79187cd13f76183c4b9100159b9e3e071",
  "third_party/opengl-registry" : "https://github.com/KhronosGroup/OpenGL-Registry@5bae8738b23d06968e7c3a41308568120943ae77",
  "third_party/SPIRV-Headers" : "https://github.com/KhronosGroup/SPIRV-Headers.git@b824a462d4256d720bebb40e78b9eb8f78bbb305",
  "third_party/SPIRV-Tools" : "https://github.com/KhronosGroup/SPIRV-Tools.git@971a7b6e8d7740035bbff089bbbf9f42951ecfd5",
  "third_party/Vulkan-Headers" : "https://github.com/KhronosGroup/Vulkan-Headers@65586d13fb197279942581ba9c2eb2c6b664487c",
  "third_party/Vulkan-Tools" : "https://github.com/KhronosGroup/Vulkan-Tools@2a3347d5e74d359e3ecb8e229917f3335bfa2dfa",
  "third_party/Vulkan-Utility-Libraries" : "https://github.com/KhronosGroup/Vulkan-Utility-Libraries@9aa2c08f82e3fb18d43e37e44015a79af7f3b672",
  "third_party/home-cube" : "https://github.com/SenorBlanco/home-cube@6d801739e9311f37826f08095d09b7345350ab59",
  "third_party/emscripten" : "https://github.com/emscripten-core/emscripten@6913738ec5371a88c4af5a80db0ab42bad3de681",
  "third_party/binaryen" : "https://github.com/WebAssembly/binaryen@6ec7b5f9c615d3b224c67ae221d6812c8f8e1a96",

  'bin': {
    'packages': [
      {
        'package': 'infra/3pp/tools/ninja/${{platform}}',
        'version': Var('ninja_version'),
      }
    ],
    'dep_type': 'cipd',
  },
}
