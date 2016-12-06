##---------------------------------------------------------------------------##
## File  : std_vector/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Mon Dec 05 09:05:31 2016
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

cmake_minimum_required(VERSION 3.0)
project(stdvec CXX Fortran)

# SWIG setup
find_package(SWIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake")
include(SwigModules)

#SET(CMAKE_CXX_FLAGS "-std=c++11")

# Build C++ library
include_directories(${CMAKE_PROJECT_SOURCE_DIR})
add_library(thinveclib stdvec.cc)

# Generate SWIG module
MAKE_SWIG(MODULE stdvec
  DEPLIBS thinveclib)

# Create test executable
add_executable(test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(test.exe stdvec)


##---------------------------------------------------------------------------##
## end of std_vector/CMakeLists.txt
##---------------------------------------------------------------------------##
