//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   thinvec/ThinVec.i
 * \author Seth R Johnson
 * \date   Mon Jan 19 08:59:42 2015
 * \note   Copyright (c) 2015 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%{
#include "ThinVec.hh"
%}

%module thinvec

#ifdef SWIGFORTRAN

%include <typemaps.i>

// Handle constructor overloading
%rename(create_count)  ThinVec::ThinVec(size_type);
%rename(create_fill)   ThinVec::ThinVec(size_type, value_type);

// Rename a function that's the same as a Fortran keyword
%rename(assign_from) ThinVec::assign;

#endif

// Handle the case of operator overloading
%rename(resize_fill) ThinVec::resize(size_type, value_type);

// Ignore return of types we don't understand
%ignore ThinVec::data() const;

// Load the thinvec class definition
%include "ThinVec.hh"

// Enable views for
FORT_VIEW_TYPEMAP("real(C_DOUBLE)", double)
FORT_VIEW_TYPEMAP("integer(C_INT)", int)

// Instantiate
%template(ThinVecDbl) ThinVec<double>;
%template(ThinVecInt) ThinVec<int>;

//---------------------------------------------------------------------------//
// end of swig-dev/thinvec/ThinVec.i
//---------------------------------------------------------------------------//
