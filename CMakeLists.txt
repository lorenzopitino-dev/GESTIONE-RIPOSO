cmake_minimum_required(VERSION 3.16)

project(Gestione_Riposo VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Cerca Qt
find_package(Qt6 REQUIRED COMPONENTS Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

# Crea l'eseguibile
qt_add_executable(appGestione_Riposo
    main.cpp
)

# Aggiunge QML e sorgenti
qt_add_qml_module(appGestione_Riposo
    URI Gestione_Riposo
    VERSION 1.0
    QML_FILES
        Main.qml
    SOURCES 
        databasemanager.h
)

# Collega le librerie
target_link_libraries(appGestione_Riposo
    PRIVATE 
    Qt6::Quick
    Qt6::Network
)

set_target_properties(appGestione_Riposo PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)