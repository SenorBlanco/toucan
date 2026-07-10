add_custom_command(
    OUTPUT "${CMAKE_BINARY_DIR}/images/toucan-logo-and-name.svg"
    COMMAND ${CMAKE_COMMAND} -E copy
            "${CMAKE_CURRENT_SOURCE_DIR}/toucan-logo-and-name.svg"
            "${CMAKE_BINARY_DIR}/config.json"
    DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/toucan-logo-and-name.svg"
    COMMENT "Copying toucan-logo-and-name.svg if it changed"
)
