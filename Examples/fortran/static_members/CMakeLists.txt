##---------------------------------------------------------------------------##
## File  : inheritance/CMakeLists.txt
## Author: Andrey Prokopenko
## Date  : Mon Jan 21 2017
## Brief : static members example
## Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

cmake_minimum_required(VERSION 3.0)
project(static_members CXX Fortran)

# SWIG setup
find_package(SWIG REQUIRED)
list(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake")
include(SwigModules)

#SET(CMAKE_CXX_FLAGS "-std=c++11")

# Build C++ library
include_directories(${CMAKE_PROJECT_SOURCE_DIR})
add_library(staticmemberslib static_members.cc)

# Generate SWIG module
MAKE_SWIG(MODULE static_members
  DEPLIBS staticmemberslib)
MESSAGE("swig name: ${SWIG_MODULE_static_members_REAL_NAME}")

set(CMAKE_Fortran_FLAGS "-cpp ${CMAKE_Fortran_FLAGS}")

# Create test executable
add_executable(test.exe test.f90)
# It depends on the compiled fortran module
target_link_libraries(test.exe ${SWIG_MODULE_static_members_REAL_NAME})

##---------------------------------------------------------------------------##
## end of static_members/CMakeLists.txt
##---------------------------------------------------------------------------##
