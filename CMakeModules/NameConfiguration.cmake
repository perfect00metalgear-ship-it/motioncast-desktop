set(MAIN_TARGET JellyfinDesktop)

# Output binary name
set(MAIN_NAME motioncast-desktop)

# Data directory name - also used for QCoreApplication::applicationName
# which determines QStandardPaths (cache, config, data dirs)
set(DATA_NAME motioncast-desktop)

if(APPLE)
  set(MAIN_NAME "MotionCast")
  set(DATA_NAME "MotionCast")
elseif(WIN32)
  set(MAIN_NAME "MotionCast")
  set(DATA_NAME "MotionCast")
endif()

configure_file(src/shared/Names.cpp.in src/shared/Names.cpp @ONLY)
