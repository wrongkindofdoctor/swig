##---------------------------------------------------------------------------##
## File  : thinvec/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Fri Dec 02 15:53:28 2016
## Brief : TriBITS package file for thinvec/
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

cmake_minimum_required(VERSION 3.0)
project(thinvec CXX Fortran)

# SWIG setup
find_package(SWIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake")
include(SwigModules)

SET(CMAKE_CXX_FLAGS "-std=c++11")

# Build C++ library
include_directories(${CMAKE_PROJECT_SOURCE_DIR})
add_library(thinveclib ThinVec.cc)

# Generate SWIG module
MAKE_SWIG(MODULE thinvec
  DEPLIBS thinveclib)

# Create test executable
add_executable(test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(test.exe thinvec)

##---------------------------------------------------------------------------##
## end of thinvec/CMakeLists.txt
##---------------------------------------------------------------------------##
