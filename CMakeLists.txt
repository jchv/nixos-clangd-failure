cmake_minimum_required(VERSION 3.20)
project(clangd-test VERSION 1.0.0 LANGUAGES CXX)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
execute_process(COMMAND ${CMAKE_COMMAND} -E create_symlink
    ${CMAKE_BINARY_DIR}/compile_commands.json
    ${CMAKE_CURRENT_SOURCE_DIR}/compile_commands.json
)
add_executable(clangd-test main.cpp)
