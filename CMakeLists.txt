cmake_minimum_required(VERSION 3.21)
project(omsnake LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

find_package(Qt6 REQUIRED COMPONENTS Core Gui Network Qml Quick QuickControls2 DBus Test)

# Everything but main.cpp, shared by the app and the tests, so each source
# compiles once and a new file in src/ needs no line here.
file(GLOB omsnake_sources CONFIGURE_DEPENDS src/*.cpp src/*.h)
list(REMOVE_ITEM omsnake_sources ${CMAKE_SOURCE_DIR}/src/main.cpp)
add_library(omsnake_core STATIC ${omsnake_sources})
target_include_directories(omsnake_core PUBLIC src)
target_link_libraries(omsnake_core PUBLIC
  Qt6::Core Qt6::Gui Qt6::Network Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::DBus)
target_compile_options(omsnake_core PUBLIC -Wall -Wextra)

add_executable(omsnake src/main.cpp src/resources.qrc)
target_link_libraries(omsnake PRIVATE omsnake_core)

# The tests load the real Main.qml, so they carry the resources too.
enable_testing()
add_executable(omsnake_tests tests/omsnake_tests.cpp src/resources.qrc)
target_link_libraries(omsnake_tests PRIVATE omsnake_core Qt6::Test)
add_test(NAME omsnake_tests COMMAND omsnake_tests)
set_tests_properties(omsnake_tests PROPERTIES ENVIRONMENT QT_QPA_PLATFORM=offscreen)

# `cmake --install build --prefix ~/.local` puts the app in the launcher
# before it is packaged; a package installs the same files under /usr.
include(GNUInstallDirs)
install(TARGETS omsnake RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES share/omsnake.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES share/omsnake.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)
install(FILES LICENSE DESTINATION ${CMAKE_INSTALL_DATADIR}/licenses/omsnake)
