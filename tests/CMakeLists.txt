cmake_minimum_required(VERSION 3.21)
project(ChinaHolidayCalendarChecks LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
find_package(Qt6 6.8 REQUIRED COMPONENTS Core)
add_executable(holiday-checks china-holiday-calendar-checks.cpp
    ../src/app/ChinaHolidayCalendar.cpp)
target_link_libraries(holiday-checks PRIVATE Qt6::Core)
qt_add_resources(holiday-checks "holiday_data" PREFIX "/holidays"
    BASE "../assets" FILES ../assets/china-holidays.json)
enable_testing()
add_test(NAME china-holiday-calendar COMMAND holiday-checks)

# 在临时目录验证旧假期记录修正、任务保护、统计与重启幂等。
add_executable(history-holiday-checks history-holiday-checks.cpp
    ../src/app/WorkHistoryStore.cpp ../src/app/WorkHistoryStore.h
    ../src/app/ChinaHolidayCalendar.cpp)
set_target_properties(history-holiday-checks PROPERTIES AUTOMOC ON)
target_link_libraries(history-holiday-checks PRIVATE Qt6::Core)
qt_add_resources(history-holiday-checks "history_holiday_data" PREFIX "/holidays"
    BASE "../assets" FILES ../assets/china-holidays.json)
add_test(NAME history-holiday-migration COMMAND history-holiday-checks)
