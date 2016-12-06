//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   swig-dev/bare_function/bare.i
 * \author Seth R Johnson
 * \date   Fri Jan 16 23:51:44 2015
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module bare

#ifdef SWIGFORTRAN

// Automatically expand a Fortran array into a pointer/size pair with the
// correct type
%apply (std::size_t SIZE) { ( std::size_t count) };
%apply (SWIGTYPE* ARRAY, std::size_t SIZE) {
       (const double* arr, std::size_t count) };

// Ignore function incompatible with Fortran language (return-by-nonconst-ref)
%ignore get_something_rref;

#endif

%{
#include "bare.hh"
%}

%include "bare.hh"

//---------------------------------------------------------------------------//
// end of swig-dev/bare_function/bare.i
//---------------------------------------------------------------------------//
