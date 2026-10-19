cmake_minimum_required(VERSION 3.14)
project(inverse_rich_edit_probe LANGUAGES CXX)
add_executable(inverse_rich_edit_probe main.cpp)
target_compile_features(inverse_rich_edit_probe PRIVATE cxx_std_17)
target_compile_definitions(inverse_rich_edit_probe PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(inverse_rich_edit_probe PRIVATE /W4 /WX /utf-8)
target_link_libraries(inverse_rich_edit_probe PRIVATE user32 gdi32 winspool)
enable_testing()
add_test(NAME native_text_device_layout
	COMMAND inverse_rich_edit_probe --native-device-text)
add_test(NAME inverse_rich_edit_layout
	COMMAND inverse_rich_edit_probe --synthetic "${CMAKE_CURRENT_BINARY_DIR}/capture")
add_test(NAME inverse_font_reference
	COMMAND inverse_rich_edit_probe --font-reference "${CMAKE_CURRENT_BINARY_DIR}/font_reference")

set(FLUTTER_EPHEMERAL "${CMAKE_CURRENT_SOURCE_DIR}/../../windows/flutter/ephemeral")
if(EXISTS "${FLUTTER_EPHEMERAL}/cpp_client_wrapper/standard_codec.cc"
    AND EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/../../third_party/native/freetype/include/ft2build.h")
  add_executable(printer_background_test
    printer_background_test.cpp
    "${FLUTTER_EPHEMERAL}/cpp_client_wrapper/core_implementations.cc"
    "${FLUTTER_EPHEMERAL}/cpp_client_wrapper/standard_codec.cc")
  target_compile_features(printer_background_test PRIVATE cxx_std_17)
  target_compile_definitions(printer_background_test PRIVATE UNICODE _UNICODE NOMINMAX)
  target_compile_options(printer_background_test PRIVATE /W4 /WX /utf-8 /wd4100)
  target_include_directories(printer_background_test PRIVATE
    "${FLUTTER_EPHEMERAL}"
    "${FLUTTER_EPHEMERAL}/cpp_client_wrapper/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/../../third_party/native/freetype/include")
  target_link_libraries(printer_background_test PRIVATE user32 gdi32 winspool
    "${FLUTTER_EPHEMERAL}/flutter_windows.dll.lib")
  add_custom_command(TARGET printer_background_test POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
      "${FLUTTER_EPHEMERAL}/flutter_windows.dll"
      "$<TARGET_FILE_DIR:printer_background_test>")
  add_test(NAME printer_background_polarity COMMAND printer_background_test)
else()
  message(STATUS "printer_background_test requires generated Flutter Windows wrappers and local FreeType headers; existing standalone probes remain available")
endif()