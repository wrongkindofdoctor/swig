##---------------------------------------------------------------------------##
## File  : exceptions/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Thu Mar 02 10:54:30 2017
## Brief : TriBITS package file for exceptions/
## Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

cmake_minimum_required(VERSION 3.0)
project(inheritance CXX Fortran)

# SWIG setup
find_package(SWIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake")
include(SwigModules)

# Build C++ library
include_directories(${CMAKE_PROJECT_SOURCE_DIR})
add_library(exceptlib except.cc)

set(CMAKE_Fortran_FLAGS "-cpp ${CMAKE_Fortran_FLAGS}")
set(CMAKE_CXX_FLAGS "-std=c++11 ${CMAKE_CXX_FLAGS}")

# Generate SWIG module
MAKE_SWIG(MODULE except
  DEPLIBS exceptlib)

# Create test executable
add_executable(test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(test.exe except)

##---------------------------------------------------------------------------##
## end of exceptions/CMakeLists.txt
##---------------------------------------------------------------------------##
