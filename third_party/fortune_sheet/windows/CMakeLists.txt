cmake_minimum_required(VERSION 3.15)
set(PROJECT_NAME "fortune_sheet")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "fortune_sheet_plugin")

add_library(${PLUGIN_NAME} SHARED
  "fortune_sheet_plugin.cpp"
)
apply_standard_settings(${PLUGIN_NAME})

target_compile_options(${PLUGIN_NAME} PRIVATE "/utf-8")

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)
target_link_libraries(${PLUGIN_NAME} PRIVATE "dwrite.lib")

set(fortune_sheet_bundled_libraries
  ""
  PARENT_SCOPE
)
