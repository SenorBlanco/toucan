# Copyright 2026 The Toucan Authors
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

set(API_HEADER "${CMAKE_CURRENT_BINARY_DIR}/api.h")

if(CMAKE_CROSSCOMPILING)
  set(API_HEADER_GEN_CMD "${CMAKE_BINARY_DIR}/host/api_header_generator")
else()
  set(API_HEADER_GEN_CMD $<TARGET_FILE:api_header_generator>)
endif()

add_custom_command(
  OUTPUT ${API_HEADER}
  COMMAND ${API_HEADER_GEN_CMD}
          -o ${API_HEADER}
          ${CMAKE_CURRENT_SOURCE_DIR}/api.t
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/api.t api_header_generator
  COMMENT "Generating api.h from api.t"
)

add_custom_target(generate_api_header DEPENDS ${API_HEADER})

add_library(api OBJECT api_dawn.cc api_image_codecs.cc)

if(WIN32)
  target_sources(api PRIVATE api_win.cc)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT EMSCRIPTEN)
  target_sources(api PRIVATE api_x11.cc)
elseif(APPLE)
  if(IOS)
    target_sources(api PRIVATE api_ios.mm)
  else()
    target_sources(api PRIVATE api_mac.mm)
  endif()
elseif(EMSCRIPTEN)
  target_sources(api PRIVATE api_wasm.cc)
elseif(ANDROID)
  target_sources(api PRIVATE api_android.cc)
  target_include_directories(api PUBLIC ${CMAKE_SOURCE_DIR}/third_party/android_native_app_glue)
endif()

add_dependencies(api generate_api_header)

target_include_directories(api PUBLIC
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/third_party/libjpeg-turbo
  ${CMAKE_SOURCE_DIR}/third_party/libultrahdr
  ${CMAKE_BINARY_DIR}/third_party/libjpeg-turbo
)

if(EMSCRIPTEN)
  add_dependencies(api emdawnwebgpu_pkg)
  target_include_directories(api PUBLIC ${CMAKE_BINARY_DIR}/emdawnwebgpu_pkg/webgpu_cpp/include)
  target_include_directories(api PUBLIC ${CMAKE_BINARY_DIR}/emdawnwebgpu_pkg/webgpu/include)
else()
  add_dependencies(api webgpu_headers_gen)
  target_include_directories(api PUBLIC
    ${CMAKE_SOURCE_DIR}/third_party/dawn/include
    ${CMAKE_BINARY_DIR}/third_party/dawn/gen/include
  )
endif()

target_link_libraries(api PUBLIC jpeg-static)
target_link_libraries(api PUBLIC uhdr)
