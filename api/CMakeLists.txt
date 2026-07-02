# api/CMakeLists.txt

set(API_HEADER "${CMAKE_CURRENT_BINARY_DIR}/api.h")

if(EMSCRIPTEN)
  if(EXISTS "${CMAKE_SOURCE_DIR}/out/Debug/bindings/api_header_generator")
    set(API_HEADER_GEN_CMD "${CMAKE_SOURCE_DIR}/out/Debug/bindings/api_header_generator")
  elseif(EXISTS "${CMAKE_SOURCE_DIR}/out/Release/bindings/api_header_generator")
    set(API_HEADER_GEN_CMD "${CMAKE_SOURCE_DIR}/out/Release/bindings/api_header_generator")
  elseif(EXISTS "${CMAKE_SOURCE_DIR}/out/Debug/api_header_generator")
    set(API_HEADER_GEN_CMD "${CMAKE_SOURCE_DIR}/out/Debug/api_header_generator")
  elseif(EXISTS "${CMAKE_SOURCE_DIR}/out/Release/api_header_generator")
    set(API_HEADER_GEN_CMD "${CMAKE_SOURCE_DIR}/out/Release/api_header_generator")
  else()
    set(API_HEADER_GEN_CMD node $<TARGET_FILE:api_header_generator>)
  endif()
else()
  set(API_HEADER_GEN_CMD $<TARGET_FILE:api_header_generator>)
endif()

add_custom_command(
  OUTPUT ${API_HEADER}
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/run.py
          ${API_HEADER_GEN_CMD}
          -o ${API_HEADER}
          ${CMAKE_CURRENT_SOURCE_DIR}/api.t
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/api.t ${CMAKE_SOURCE_DIR}/tools/run.py
  COMMENT "Generating api.h from api.t"
)

add_custom_target(generate_api_header DEPENDS ${API_HEADER})

set(DAWN_GEN_DIR "${CMAKE_CURRENT_BINARY_DIR}/gen/third_party/dawn")
set(DAWN_GEN_HEADERS
  "${DAWN_GEN_DIR}/include/dawn/webgpu_cpp.h"
  "${DAWN_GEN_DIR}/include/dawn/webgpu.h"
  "${DAWN_GEN_DIR}/include/dawn/dawn_proc_table.h"
  "${DAWN_GEN_DIR}/include/dawn/webgpu_cpp_print.h"
  "${DAWN_GEN_DIR}/include/webgpu/webgpu_cpp_chained_struct.h"
  "${DAWN_GEN_DIR}/src/emdawnwebgpu/include/webgpu/webgpu_cpp.h"
)

add_custom_command(
  OUTPUT ${DAWN_GEN_HEADERS}
  COMMAND ${CMAKE_COMMAND} -E env
          "PYTHONPATH=${CMAKE_SOURCE_DIR}/third_party:${CMAKE_SOURCE_DIR}/third_party/jinja2:${CMAKE_SOURCE_DIR}/third_party/markupsafe"
          ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/third_party/dawn/generator/dawn_json_generator.py
          --template-dir ${CMAKE_SOURCE_DIR}/third_party/dawn/generator/templates
          --root-dir ${CMAKE_SOURCE_DIR}/third_party/dawn
          --output-dir ${DAWN_GEN_DIR}
          --dawn-json ${CMAKE_SOURCE_DIR}/third_party/dawn/src/dawn/dawn.json
          --wire-json ${CMAKE_SOURCE_DIR}/third_party/dawn/src/dawn/dawn_wire.json
          --targets headers,cpp_headers,emdawnwebgpu_headers
  DEPENDS ${CMAKE_SOURCE_DIR}/third_party/dawn/src/dawn/dawn.json
          ${CMAKE_SOURCE_DIR}/third_party/dawn/src/dawn/dawn_wire.json
  COMMENT "Generating Dawn WebGPU headers"
)

add_custom_target(generate_dawn_headers DEPENDS ${DAWN_GEN_HEADERS})

set(API_SOURCES
  api_dawn.cc
  api_image_codecs.cc
)

if(WIN32)
  list(APPEND API_SOURCES api_win.cc)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT EMSCRIPTEN)
  list(APPEND API_SOURCES api_x11.cc)
elseif(APPLE)
  if(IOS)
    list(APPEND API_SOURCES api_ios.mm)
  else()
    list(APPEND API_SOURCES api_mac.mm)
  endif()
elseif(EMSCRIPTEN)
  list(APPEND API_SOURCES api_wasm.cc)
elseif(ANDROID)
  list(APPEND API_SOURCES api_android.cc)
endif()

add_library(api STATIC ${API_SOURCES})

add_dependencies(api generate_api_header generate_dawn_headers)

target_include_directories(api PUBLIC
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/third_party/libjpeg-turbo
  ${CMAKE_SOURCE_DIR}/third_party/build/libjpeg-turbo
)

if(EMSCRIPTEN)
  target_compile_definitions(api PUBLIC TARGET_OS_IS_WASM=1 TARGET_CPU_IS_WASM=1)
  target_include_directories(api BEFORE PUBLIC
    ${DAWN_GEN_DIR}/src/emdawnwebgpu/include
    ${DAWN_GEN_DIR}/include
    ${CMAKE_SOURCE_DIR}/third_party/dawn/include
  )
else()
  target_include_directories(api PUBLIC
    ${CMAKE_SOURCE_DIR}/third_party/dawn/include
    ${DAWN_GEN_DIR}/include
    ${CMAKE_SOURCE_DIR}/third_party/Vulkan-Headers/include
  )
endif()

target_link_libraries(api PUBLIC libjpeg-turbo)

if(TARGET dawn_native_headers)
  target_link_libraries(api PRIVATE dawn_native_headers)
endif()
