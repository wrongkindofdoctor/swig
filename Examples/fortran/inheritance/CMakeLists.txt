##---------------------------------------------------------------------------##
## File  : inheritance/CMakeLists.txt
## Author: Mitchell TH Young
## Date  : Mon Jan  2 2017
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

cmake_minimum_required(VERSION 3.0)
project(inheritance CXX Fortran)

# SWIG setup
find_package(SWIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake")
include(SwigModules)

# Build C++ library
include_directories(${CMAKE_PROJECT_SOURCE_DIR})
add_library(classeslib classes.cc)

set(CMAKE_Fortran_FLAGS "-cpp ${CMAKE_Fortran_FLAGS}")
set(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")

# Generate SWIG module
MAKE_SWIG(MODULE classes
  DEPLIBS classeslib)

# Create test executable
add_executable(test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(test.exe classes)

##---------------------------------------------------------------------------##
## end of inheritance/CMakeLists.txt
##---------------------------------------------------------------------------##
