##---------------------------------------------------------------------------##
## File  : algorithm/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Tue Dec 06 11:46:55 2016
## Brief : TriBITS package file for algorithm/
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

CMAKE_MINIMUM_REQUIRED(VERSION 3.0)
PROJECT(fortran-examples CXX Fortran)

SET(CMAKE_CXX_STANDARD 11)

ENABLE_TESTING()

# SWIG setup
FIND_PACKAGE(SWIG REQUIRED)
LIST(APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake")
INCLUDE(SwigModules)

ADD_SUBDIRECTORY(algorithm)
ADD_SUBDIRECTORY(barefunctions)
ADD_SUBDIRECTORY(class)
ADD_SUBDIRECTORY(exceptions)
ADD_SUBDIRECTORY(funcptr)
ADD_SUBDIRECTORY(inheritance)
ADD_SUBDIRECTORY(simple)
ADD_SUBDIRECTORY(simpleclass)
ADD_SUBDIRECTORY(spdemo)
ADD_SUBDIRECTORY(static_members)
ADD_SUBDIRECTORY(std_string)
ADD_SUBDIRECTORY(std_vector)
ADD_SUBDIRECTORY(thinvec)

##---------------------------------------------------------------------------##
## end of algorithm/CMakeLists.txt
##---------------------------------------------------------------------------##
