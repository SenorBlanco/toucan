add_library(gen_bindings_sources STATIC
  gen_bindings.cc
)

target_include_directories(gen_bindings_sources PUBLIC
  ${CMAKE_SOURCE_DIR}
)

target_link_libraries(gen_bindings_sources PUBLIC ast)

if(CMAKE_CROSSCOMPILING)
  include(ExternalProject)
  ExternalProject_Add(api_header_generator
      SOURCE_DIR ${CMAKE_SOURCE_DIR}
      CMAKE_ARGS -DCMAKE_CROSSCOMPILING=OFF -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} -UCMAKE_TOOLCHAIN_FILE
      BINARY_DIR ${CMAKE_BINARY_DIR}/host
      INSTALL_COMMAND ""                    # No install step needed
      BUILD_COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR}/host --target api_header_generator
      BUILD_BYPRODUCTS ${CMAKE_BINARY_DIR}/host/bindings/api_header_generator
      USES_TERMINAL_BUILD TRUE
  )

  set(HOST_GENERATOR_EXE ${CMAKE_BINARY_DIR}/host/bindings/api_header_generator)

  # 4. Define custom command to generate files using the host tool
  set(GENERATED_OUTPUT_FILE ${CMAKE_CURRENT_BINARY_DIR}/api.h)

  add_custom_command(
      OUTPUT ${GENERATED_OUTPUT_FILE}
      COMMAND ${HOST_GENERATOR_EXE} --output ${GENERATED_OUTPUT_FILE}
      DEPENDS api_heaer_generator ${CMAKE_CURRENT_SOURCE_DIR}/api_header_generator_main.cc ${CMAKE_CURRENT_SOURCE_DIR}/api_header_generator.cc
      COMMENT "Running api_header_generator to produce api.h..."
  )

else()
  add_executable(api_header_generator
    api_header_generator_main.cc
    api_header_generator.cc
  )
  export(PACKAGE APIHeaderGenerator)

  target_include_directories(api_header_generator PUBLIC
    ${CMAKE_SOURCE_DIR}
  )

  target_link_libraries(api_header_generator PRIVATE
    ast
    parser
  )

  if(WIN32)
    target_include_directories(api_header_generator PRIVATE
      ${CMAKE_SOURCE_DIR}/third_party/getopt
    )
  endif()
endif()
