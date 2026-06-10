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
  "third_party/getopt"                 : "https://github.com/skeeto/getopt@4e618ef782dc80b2cf0307ea74b68e6a62b025de",
  "third_party/llvm" : "https://github.com/llvm/llvm-project@216e85bdda22ae7eda3f3e04c51d9d6d82e2b617",
  "third_party/dawn" : "https://dawn.googlesource.com/dawn.git@e8fdf6b115d128adc6ad29e91d38d32f60eb91f0",
  "third_party/libjpeg-turbo" : "https://github.com/libjpeg-turbo/libjpeg-turbo@3b19db4e6e7493a748369974819b4c5fa84c7614",
  "third_party/home-cube" : "https://github.com/SenorBlanco/home-cube@21b23e4d7c46100652d59b320b633fd8a7edec3e",
  "third_party/libultrahdr" : "https://github.com/google/libultrahdr.git@d52a0d13814ca399fc8a07e23de1d2c63f0e8404",
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
