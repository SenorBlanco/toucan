# api/CMakeLists.txt

set(API_HEADER "${CMAKE_CURRENT_BINARY_DIR}/api.h")

add_custom_command(
  OUTPUT ${API_HEADER}
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/run.py
          $<TARGET_FILE:api_header_generator>
          -o ${API_HEADER}
          ${CMAKE_CURRENT_SOURCE_DIR}/api.t
  DEPENDS api_header_generator ${CMAKE_CURRENT_SOURCE_DIR}/api.t ${CMAKE_SOURCE_DIR}/tools/run.py
  COMMENT "Generating api.h from api.t"
)

add_custom_target(generate_api_header DEPENDS ${API_HEADER})

set(API_SOURCES
  api_dawn.cc
  api_image_codecs.cc
)

if(WIN32)
  list(APPEND API_SOURCES api_win.cc)
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
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

add_dependencies(api generate_api_header)

target_include_directories(api PUBLIC
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_CURRENT_BINARY_DIR}
  ${CMAKE_SOURCE_DIR}/third_party/dawn/include
  ${CMAKE_SOURCE_DIR}/out/Debug/gen/third_party/dawn/include
  ${CMAKE_SOURCE_DIR}/out/Release/gen/third_party/dawn/include
  ${CMAKE_SOURCE_DIR}/third_party/libjpeg-turbo
  ${CMAKE_SOURCE_DIR}/third_party/build/libjpeg-turbo
  ${CMAKE_SOURCE_DIR}/third_party/Vulkan-Headers/include
)

target_link_libraries(api PUBLIC libjpeg-turbo)

if(TARGET dawn_native_headers)
  target_link_libraries(api PRIVATE dawn_native_headers)
endif()
