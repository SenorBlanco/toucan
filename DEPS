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
  "buildtools"                            : "https://chromium.googlesource.com/chromium/src/buildtools@958004daacdd90070d44b236a1581c81d71740ca",
  "third_party/abseil-cpp"             : "https://chromium.googlesource.com/chromium/src/third_party/abseil-cpp@9d692d669253232c024b20ae19d2ff0b581ee1cd",
  "third_party/getopt"                 : "https://github.com/skeeto/getopt@4e618ef782dc80b2cf0307ea74b68e6a62b025de",
  "third_party/llvm" : "https://github.com/llvm/llvm-project@216e85bdda22ae7eda3f3e04c51d9d6d82e2b617",
  "third_party/dawn" : "https://dawn.googlesource.com/dawn.git@89872eaabc3dade72f429eb25b9053609d1bdfd1",
  "third_party/jinja2" : "https://chromium.googlesource.com/chromium/src/third_party/jinja2@e2d024354e11cc6b041b0cff032d73f0c7e43a07",
  "third_party/libjpeg-turbo" : "https://github.com/libjpeg-turbo/libjpeg-turbo@3b19db4e6e7493a748369974819b4c5fa84c7614",
  "third_party/markupsafe": "https://chromium.googlesource.com/chromium/src/third_party/markupsafe@0bad08bb207bbfc1d6f3bbc82b9242b0c50e5794",
  "third_party/egl-registry" : "https://github.com/KhronosGroup/EGL-Registry@7dea2ed79187cd13f76183c4b9100159b9e3e071",
  "third_party/opengl-registry" : "https://github.com/KhronosGroup/OpenGL-Registry@5bae8738b23d06968e7c3a41308568120943ae77",
  "third_party/SPIRV-Headers" : "https://github.com/KhronosGroup/SPIRV-Headers.git@a5164829e8f0255392c481696b63763a5e80be3c",
  "third_party/SPIRV-Tools" : "https://github.com/KhronosGroup/SPIRV-Tools.git@b9997dafc791634ce51f6bed7ab886ea0e600a15",
  "third_party/Vulkan-Headers" : "https://github.com/KhronosGroup/Vulkan-Headers@f5fad0a209a2e09eb5e622d930d5eade1a235b13",
  "third_party/Vulkan-Tools" : "https://github.com/KhronosGroup/Vulkan-Tools@faf69f66f2d9ba782fe37cabd19b9742f9f62eb3",
  "third_party/Vulkan-Utility-Libraries" : "https://github.com/KhronosGroup/Vulkan-Utility-Libraries@a1e45945b3a84140956dc4672684090cf8e636a4",
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
