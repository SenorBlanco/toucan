cmake_minimum_required(VERSION 3.20)

project(Toucan CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(POLICY CMP0171)
  cmake_policy(SET CMP0171 OLD)
endif()



option(BUILD_SAMPLES "Build Toucan samples" ON)
option(BUILD_TESTS "Build Toucan tests" ON)

find_package(Python3 REQUIRED COMPONENTS Interpreter)

# Locate LLVM
find_package(LLVM CONFIG HINTS
  "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Debug"
  "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Release"
  "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out"
  QUIET
)

if(LLVM_FOUND)
  message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
  message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
  if(TARGET LLVM)
    set(LLVM_LIBRARIES LLVM)
  elseif(TARGET LLVM-dynamic)
    set(LLVM_LIBRARIES LLVM-dynamic)
  else()
    list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
    include(AddLLVM)
    llvm_map_components_to_libnames(LLVM_LIBRARIES
      core
      support
      executionengine
      mcjit
      target
      native
      webassemblycodegen
      webassemblydesc
      webassemblyinfo
    )
  endif()
else()
  message(STATUS "System/Prebuilt LLVM config not found directly via find_package. Setting fallback include paths.")
  set(LLVM_INCLUDE_DIRS
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/include"
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Debug/include"
    "${CMAKE_SOURCE_DIR}/third_party/llvm/llvm/out/Release/include"
  )
  set(LLVM_LIBRARIES LLVM)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")
include(ToucanMacros)

add_subdirectory(third_party/build/libjpeg-turbo)
add_subdirectory(parser)
add_subdirectory(ast)
add_subdirectory(bindings)
add_subdirectory(api)
add_subdirectory(codegen)
add_subdirectory(compilers)
add_subdirectory(samples)
add_subdirectory(test)
