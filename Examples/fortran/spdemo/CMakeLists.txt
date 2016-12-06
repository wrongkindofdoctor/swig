##---------------------------------------------------------------------------##
## File  : spdemo/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Tue Dec 06 14:55:04 2016
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

cmake_minimum_required(VERSION 3.1)
project(spdemo CXX Fortran)

set(CMAKE_CXX_STANDARD 11)

# SWIG setup
find_package(SWIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake")
include(SwigModules)

# Build C++ library
include_directories(${CMAKE_PROJECT_SOURCE_DIR})
add_library(spdemolib spdemo.cc)

# Generate SWIG module
MAKE_SWIG(MODULE spdemo
  DEPLIBS spdemolib)

# Create test executable
add_executable(test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(test.exe spdemo)

##---------------------------------------------------------------------------##
## end of spdemo/CMakeLists.txt
##---------------------------------------------------------------------------##
