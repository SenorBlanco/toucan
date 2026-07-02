# Toucan CMake helper macros and functions

function(toucan_objects TARGET_NAME)
  cmake_parse_arguments(ARG "" "" "SOURCES" ${ARGN})

  set(MAKE_ACTION "make_${TARGET_NAME}")
  set(OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.o")
  set(INIT_TYPES_CC "${CMAKE_CURRENT_BINARY_DIR}/init_types_${TARGET_NAME}.cc")

  set(ABS_SOURCES "")
  foreach(src ${ARG_SOURCES})
    if(IS_ABSOLUTE "${src}")
      list(APPEND ABS_SOURCES "${src}")
    else()
      list(APPEND ABS_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/${src}")
    endif()
  endforeach()

  add_custom_command(
    OUTPUT ${OBJ_FILE} ${INIT_TYPES_CC}
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/run.py
            $<TARGET_FILE:tc>
            -o ${OBJ_FILE}
            -t ${INIT_TYPES_CC}
            -I ${CMAKE_SOURCE_DIR}
            -I ${CMAKE_SOURCE_DIR}/samples/include
            ${ABS_SOURCES}
    DEPENDS tc ${ABS_SOURCES} ${CMAKE_SOURCE_DIR}/tools/run.py
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Compiling Toucan sources for ${TARGET_NAME}"
  )

  add_custom_target(${MAKE_ACTION} DEPENDS ${OBJ_FILE} ${INIT_TYPES_CC})
endfunction()

function(toucan_executable TARGET_NAME)
  cmake_parse_arguments(ARG "" "" "SOURCES" ${ARGN})

  toucan_objects(${TARGET_NAME} SOURCES ${ARG_SOURCES})

  set(OBJ_FILE "${CMAKE_CURRENT_BINARY_DIR}/${TARGET_NAME}.o")
  set(INIT_TYPES_CC "${CMAKE_CURRENT_BINARY_DIR}/init_types_${TARGET_NAME}.cc")

  add_executable(${TARGET_NAME} ${INIT_TYPES_CC})

  # Set object files as extra source/object input
  target_sources(${TARGET_NAME} PRIVATE ${OBJ_FILE})

  target_include_directories(${TARGET_NAME} PRIVATE ${CMAKE_SOURCE_DIR})

  target_link_directories(${TARGET_NAME} PRIVATE
    ${CMAKE_SOURCE_DIR}/out/Debug
    ${CMAKE_SOURCE_DIR}/out/Release
  )

  target_link_libraries(${TARGET_NAME} PRIVATE
    samples_main
    api
    ast
    dawn_proc
    dawn_native
  )

  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(${TARGET_NAME} PRIVATE X11 X11-xcb dl pthread)
  elseif(APPLE)
    find_library(APPKIT_FRAMEWORK AppKit)
    find_library(METAL_FRAMEWORK Metal)
    find_library(QUARTZCORE_FRAMEWORK QuartzCore)
    target_link_libraries(${TARGET_NAME} PRIVATE
      ${APPKIT_FRAMEWORK}
      ${METAL_FRAMEWORK}
      ${QUARTZCORE_FRAMEWORK}
    )
  elseif(WIN32)
    target_link_libraries(${TARGET_NAME} PRIVATE gdi32 user32)
  endif()
endfunction()

function(toucan_app TARGET_NAME)
  toucan_executable(${TARGET_NAME} ${ARGN})
endfunction()
