cmake_minimum_required(VERSION 3.16)

project(Gestione_Riposo VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

# Eseguibile WebAssembly
qt_add_executable(appGestione_Riposo
    main.cpp
    databasemanager.cpp
    databasemanager.h
)

# Modulo QML
qt_add_qml_module(appGestione_Riposo
    URI Gestione_Riposo
    VERSION 1.0
    QML_FILES
        Main.qml
)

target_link_libraries(appGestione_Riposo
    PRIVATE Qt6::Quick Qt6::Network
)

# 🔥 QUI LA MAGIA: output diretto nella cartella del progetto
set_target_properties(appGestione_Riposo PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}"
)
