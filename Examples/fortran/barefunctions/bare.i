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

%include <typemaps.i>

// Instantiate array pointer conversion for doubles from pair<double*,size_t>
%fortran_view(double)

// Ignore function incompatible with Fortran language (return-by-nonconst-ref)
%ignore get_something_rptr;

#endif

%{
#include "bare.hh"
%}

%include "bare.hh"

//---------------------------------------------------------------------------//
// end of swig-dev/bare_function/bare.i
//---------------------------------------------------------------------------//
