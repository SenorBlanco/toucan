# ast/CMakeLists.txt

set(AST_SOURCES
  ${CMAKE_CURRENT_SOURCE_DIR}/api_validator.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/ast.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/constant_folder.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/copy_visitor.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/file_location.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/name_mangler.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/native_class.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/semantic_pass.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/shader_prep_pass.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/shader_validation_pass.cc
  ${CMAKE_CURRENT_SOURCE_DIR}/type.cc
  PARENT_SCOPE
)

add_library(ast STATIC
  api_validator.cc
  ast.cc
  constant_folder.cc
  copy_visitor.cc
  file_location.cc
  name_mangler.cc
  native_class.cc
  semantic_pass.cc
  shader_prep_pass.cc
  shader_validation_pass.cc
  type.cc
)

target_include_directories(ast PUBLIC
  ${CMAKE_SOURCE_DIR}
)
