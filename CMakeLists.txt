cmake_minimum_required(VERSION 3.16)

project(mwrap LANGUAGES C CXX)

set(MWRAP_PROFILE "USER" CACHE STRING "Select the mwrap build profile (USER or DEVELOPER)")
set_property(CACHE MWRAP_PROFILE PROPERTY STRINGS USER DEVELOPER)

option(MWRAP_ENABLE_MATLAB_CLASSDEF "Enable MATLAB classdef support (adds -DR2008OO)" OFF)
option(MWRAP_ENABLE_C99_COMPLEX "Enable C99 complex support helpers" OFF)
option(MWRAP_ENABLE_CPP_COMPLEX "Enable C++ complex support helpers" OFF)
option(MWRAP_BUILD_EXAMPLES "Build the MATLAB/Octave examples" OFF)
option(MWRAP_COMPILE_MEX "Compile generated wrappers into MEX binaries" OFF)

if(MWRAP_COMPILE_MEX)
  find_package(Matlab COMPONENTS MEX_COMPILER MX_LIBRARY REQUIRED)
endif()

add_subdirectory(src)

if(MWRAP_BUILD_EXAMPLES)
  add_subdirectory(example)
endif()
