cmake_minimum_required(VERSION 3.21)

project(NiumaTimer VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Network Qml Quick QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(NiumaTimer
    src/main.cpp
    src/app/NetworkClock.cpp
    src/app/NetworkClock.h
    src/app/WorkTimer.cpp
    src/app/WorkTimer.h
    src/app/WorkHistoryStore.cpp
    src/app/WorkHistoryStore.h
    src/app/ChinaHolidayCalendar.cpp
    src/app/ChinaHolidayCalendar.h
)

qt_add_resources(NiumaTimer "holiday_data"
    PREFIX "/holidays"
    BASE "assets"
    FILES assets/china-holidays.json
)

set_source_files_properties(src/ui/Theme.qml PROPERTIES
    QT_QML_SINGLETON_TYPE TRUE
    QT_RESOURCE_ALIAS "Theme.qml"
)
set_source_files_properties(src/ui/Main.qml PROPERTIES QT_RESOURCE_ALIAS "Main.qml")

qt_add_qml_module(NiumaTimer
    URI NiumaTimer
    VERSION 1.0
    QML_FILES
        src/ui/Theme.qml
        src/ui/Main.qml
        src/ui/AppShell.qml
        src/ui/HomePage.qml
        src/ui/HolidayCountdownCard.qml
        src/ui/PixelPanel.qml
        src/ui/PixelMeter.qml
        src/ui/PixelDigits.qml
        src/ui/PixelIcon.qml
        src/ui/QuickScheduleCard.qml
        src/ui/TasksPage.qml
        src/ui/StatisticsPage.qml
        src/ui/SalarySettingsPage.qml
        src/ui/ScheduleSettingsPage.qml
        src/ui/AchievementsPage.qml
        src/ui/AppearancePage.qml
        src/ui/AboutPage.qml
    RESOURCES
        assets/worker-cow-mascot.png
        assets/office-city-panorama.png
        assets/cow-fatigue-spritesheet.png
        assets/office-pixel-v2.png
)

target_link_libraries(NiumaTimer PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

set_target_properties(NiumaTimer PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE TRUE
    QT_ANDROID_PACKAGE_NAME "com.codex.niumatimer"
    QT_ANDROID_VERSION_CODE 1
    QT_ANDROID_VERSION_NAME "0.1.0"
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
)
