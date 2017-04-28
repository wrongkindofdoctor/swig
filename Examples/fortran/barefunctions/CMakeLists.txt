##---------------------------------------------------------------------------##
## File  : bare_function/CMakeLists.txt
## Author: Seth R Johnson
## Date  : Thu Dec 01 13:18:51 2016
## Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
##---------------------------------------------------------------------------##

# Build C++ library
INCLUDE_DIRECTORIES(${CMAKE_PROJECT_SOURCE_DIR})
ADD_LIBRARY(barelib bare.cxx)

# Generate SWIG module
MAKE_SWIG(MODULE bare
    DEPLIBS barelib)

# Create test executable
ADD_EXECUTABLE(bare_test.exe runme.f90)
# It depends on the compiled fortran module
TARGET_LINK_LIBRARIES(bare_test.exe ${SWIG_MODULE_bare_REAL_NAME})

# Create test
ADD_TEST(NAME bare_test COMMAND bare_test.exe)

##---------------------------------------------------------------------------##
## end of bare_function/CMakeLists.txt
##---------------------------------------------------------------------------##
