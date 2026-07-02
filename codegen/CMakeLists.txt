# codegen/CMakeLists.txt

add_library(codegen STATIC
  codegen_llvm.cc
  codegen_spirv.cc
)

target_include_directories(codegen PUBLIC
  ${CMAKE_SOURCE_DIR}
  ${CMAKE_BINARY_DIR}/bindings
  ${CMAKE_SOURCE_DIR}/third_party/SPIRV-Headers/include
)

if(LLVM_INCLUDE_DIRS)
  target_include_directories(codegen PUBLIC ${LLVM_INCLUDE_DIRS})
endif()

target_link_libraries(codegen PUBLIC
  ast
)
