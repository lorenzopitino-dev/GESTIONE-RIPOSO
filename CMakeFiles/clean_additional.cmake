# Additional clean files
cmake_minimum_required(VERSION 3.16)

if("${CONFIG}" STREQUAL "" OR "${CONFIG}" STREQUAL "")
  file(REMOVE_RECURSE
  "CMakeFiles\\appGestione_Riposo_autogen.dir\\AutogenUsed.txt"
  "CMakeFiles\\appGestione_Riposo_autogen.dir\\ParseCache.txt"
  "appGestione_Riposo_autogen"
  )
endif()
