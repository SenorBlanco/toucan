# compilers/CMakeLists.txt

if(NOT EMSCRIPTEN)
  add_executable(tc tc.cc)

  target_include_directories(tc PRIVATE
    ${CMAKE_SOURCE_DIR}
  )

  if(LLVM_INCLUDE_DIRS)
    target_include_directories(tc PRIVATE ${LLVM_INCLUDE_DIRS})
  endif()

  target_compile_definitions(tc PRIVATE API_PATH="${CMAKE_SOURCE_DIR}/api")

  target_link_libraries(tc PRIVATE
    ast
    gen_bindings_sources
    codegen
    parser
  )

  if(LLVM_LIBRARIES)
    target_link_libraries(tc PRIVATE ${LLVM_LIBRARIES})
  endif()

  if(WIN32)
    target_include_directories(tc PRIVATE ${CMAKE_SOURCE_DIR}/third_party/getopt)
  endif()

  add_executable(tj tj.cc)
  set_target_properties(tj PROPERTIES ENABLE_EXPORTS TRUE)

  target_include_directories(tj PRIVATE
    ${CMAKE_SOURCE_DIR}
  )

  if(LLVM_INCLUDE_DIRS)
    target_include_directories(tj PRIVATE ${LLVM_INCLUDE_DIRS})
  endif()

  target_compile_definitions(tj PRIVATE API_PATH="${CMAKE_SOURCE_DIR}/api")

  target_link_directories(tj PRIVATE
    ${CMAKE_SOURCE_DIR}/out/Debug
    ${CMAKE_SOURCE_DIR}/out/Release
  )

  target_link_libraries(tj PRIVATE
    api
    ast
    codegen
    parser
    dawn_proc
    dawn_native
  )

  if(LLVM_LIBRARIES)
    target_link_libraries(tj PRIVATE ${LLVM_LIBRARIES})
  endif()

  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(tj PRIVATE X11 X11-xcb dl pthread z zstd curses)
  elseif(APPLE)
    find_library(APPKIT_FRAMEWORK AppKit)
    find_library(METAL_FRAMEWORK Metal)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore)
    target_link_libraries(tj PRIVATE
      ${APPKIT_FRAMEWORK}
      ${METAL_FRAMEWORK}
      ${QUARTZCORE_FRAMEWORK}
      z curses
    )
  elseif(WIN32)
    target_include_directories(tj PRIVATE ${CMAKE_SOURCE_DIR}/third_party/getopt)
    target_link_libraries(tj PRIVATE gdi32 user32 ws2_32 ntdll)
  endif()
endif()
