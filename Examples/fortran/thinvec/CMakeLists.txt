##---------------------------------------------------------------------------##
## File  : thinvec/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Fri Dec 02 15:53:28 2016
## Brief : TriBITS package file for thinvec/
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

SET(CMAKE_CXX_FLAGS "-std=c++11")

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})
ADD_LIBRARY(thinveclib ThinVec.cc)

# Generate SWIG module
MAKE_SWIG(MODULE thinvec
  DEPLIBS thinveclib)

# Create test executable
ADD_EXECUTABLE(thinvec_test.exe test.f90)
# It depends on the compiled fortran module
TARGET_LINK_LIBRARIES(thinvec_test.exe ${SWIG_MODULE_thinvec_REAL_NAME})

##---------------------------------------------------------------------------##
## end of thinvec/CMakeLists.txt
##---------------------------------------------------------------------------##
