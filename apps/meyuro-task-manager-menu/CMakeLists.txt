# SPDX-License-Identifier: GPL-3.0-or-later

cmake_minimum_required(VERSION 3.20)

set(QT_MIN_VERSION "6.5.0")
set(KF6_MIN_VERSION "6.0.0")
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

project(meyuro_task_manager_menu VERSION 0.1.0 LANGUAGES CXX)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECompilerSettings NO_POLICY_SCOPE)
include(KDECMakeSettings)

add_definitions(-DTRANSLATION_DOMAIN="meyuro_task_manager_menu")

# PlasmaConfig currently imports PlasmaTargets before resolving all of the
# public targets referenced by Plasma::Plasma. Load those targets explicitly
# first so this also configures correctly with CMake 4 on Fedora/Bazzite.
find_package(Qt6 ${QT_MIN_VERSION} CONFIG REQUIRED COMPONENTS Core Gui Qml Widgets)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    Config
    CoreAddons
    I18n
    KirigamiPlatform
    Package
    WindowSystem
)
find_package(Plasma 6.0 REQUIRED)

kcoreaddons_add_plugin(meyuro_task_manager_contextmenu
    SOURCES
        src/taskbarcontextmenu.cpp
        src/taskbarcontextmenu.h
    INSTALL_NAMESPACE "plasma/containmentactions"
)

set_target_properties(meyuro_task_manager_contextmenu PROPERTIES
    OUTPUT_NAME org.meyuroos.contextmenu
)

target_link_libraries(meyuro_task_manager_contextmenu PRIVATE
    Qt6::Core
    Qt6::Widgets
    KF6::CoreAddons
    KF6::I18n
    Plasma::Plasma
)
