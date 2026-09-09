cmake_minimum_required(VERSION 3.14)
project(inverse_rich_edit_probe LANGUAGES CXX)
add_executable(inverse_rich_edit_probe main.cpp)
target_compile_features(inverse_rich_edit_probe PRIVATE cxx_std_17)
target_compile_definitions(inverse_rich_edit_probe PRIVATE UNICODE _UNICODE NOMINMAX)
target_compile_options(inverse_rich_edit_probe PRIVATE /W4 /WX /utf-8)
target_link_libraries(inverse_rich_edit_probe PRIVATE user32 gdi32 winspool)
enable_testing()
add_test(NAME inverse_rich_edit_layout
	COMMAND inverse_rich_edit_probe --synthetic "${CMAKE_CURRENT_BINARY_DIR}/capture")
add_test(NAME inverse_font_reference
	COMMAND inverse_rich_edit_probe --font-reference "${CMAKE_CURRENT_BINARY_DIR}/font_reference")