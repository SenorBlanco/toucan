# ast/CMakeLists.txt

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
