##---------------------------------------------------------------------------##
## File  : algorithm/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Tue Dec 06 11:46:55 2016
## Brief : TriBITS package file for algorithm/
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(fortran-examples CXX Fortran)

ENABLE_TESTING()

# SWIG setup
FIND_PACKAGE(SWIG REQUIRED)
LIST(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
INCLUDE(SwigModules)

# SET(CMAKE_CXX_FLAGS "-std=c++11")

SET(DIR ${CMAKE_CURRENT_SOURCE_DIR})
ADD_SUBDIRECTORY(${DIR}/algorithm)
ADD_SUBDIRECTORY(${DIR}/barefunctions)
# ADD_SUBDIRECTORY(${DIR}/char)
# ADD_SUBDIRECTORY(${DIR}/class)
# ADD_SUBDIRECTORY(${DIR}/exceptions)
ADD_SUBDIRECTORY(${DIR}/inheritance)
# ADD_SUBDIRECTORY(${DIR}/simple)
# ADD_SUBDIRECTORY(${DIR}/simpleclass)
# ADD_SUBDIRECTORY(${DIR}/spdemo)
# ADD_SUBDIRECTORY(${DIR}/static_members)
ADD_SUBDIRECTORY(${DIR}/std_string)
ADD_SUBDIRECTORY(${DIR}/std_vector)
# ADD_SUBDIRECTORY(${DIR}/thinvec)

##---------------------------------------------------------------------------##
## end of algorithm/CMakeLists.txt
##---------------------------------------------------------------------------##
