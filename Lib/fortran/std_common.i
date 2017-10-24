//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_common.i
 * \author Seth R Johnson
 * \date   Tue May 09 15:35:04 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

/* Note that to make generic binding automatic for the default fortran integer
 * type, we use "int" as value_type .
 * Otherwise you get:
   /Users/s3j/_code/swig/Examples/fortran/std_vector/test.f90:27:10:

     call v%resize(4)
          1
 Error: Found no matching specific binding for the call to the GENERIC 'resize' at (1)
 */

#ifndef SWIG_FORTRAN_STD_SIZETYPE
#define SWIG_FORTRAN_STD_SIZETYPE int
#endif

//---------------------------------------------------------------------------//
// end of fortran/std_common.i
//---------------------------------------------------------------------------//
