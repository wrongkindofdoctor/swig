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

%include <typemaps.i>
%fortran_view(int)
%fortran_view(double)

// Handle constructor overloading
%rename(create_ThinVec_count)  ThinVec::ThinVec(size_type);
%rename(create_ThinVec_fill)   ThinVec::ThinVec(size_type, value_type);

// Rename a function that's the same as a Fortran keyword
%rename(assign_from) ThinVec::assign;

// Handle the case of operator overloading
%rename(resize_fill) ThinVec::resize(size_type, value_type);

// Ignore return of types we don't understand (to prevent a warning)
%ignore ThinVec::data() const;

//---------------------------------------------------------------------------//
#define THINVEC_T const ThinVec<int>& INDICES

// Note: since we use %const_cast and %static_cast, which are SWIG-defined
// macros, we must use {} rather than %{ %} for the typemap. To prevent those
// enclosing braces from being inserted in the wrapper code, we add the
// noblock=1 argument to the typemap.
//
// The typemap applies to type pattern THINVEC_T, and it uses a temporary
// variable (called tempvec) in the parentheses.
%typemap(in, noblock=1) THINVEC_T (ThinVec<int> tempvec)
{
    // Original typemap: convert const ThinVec<int>* to thinvec reference
    $1 = %static_cast($input->ptr, $1_ltype);
    // Resize temporary vec
    tempvec.resize($1->size());
    // Copy input vector incremented by one
    $*1_ltype::const_iterator src = $1->begin();
    for ($*1_ltype::iterator dst = tempvec.begin();
         dst != tempvec.end();
         ++dst)
    {
        *dst = *src++ + 1;
    }
    // Make the input argument point to our temporary vector
    $1 = &tempvec;
}
#undef THINVEC_T

// Load the thinvec class definition
%include "ThinVec.hh"

// Instantiate classes
%template(ThinVecDbl) ThinVec<double>;
%template(ThinVecInt) ThinVec<int>;

// Instantiate functions
%template(print_vec) print_vec<double>;
%template(print_vec) print_vec<int>;

//---------------------------------------------------------------------------//
// end of swig-dev/thinvec/ThinVec.i
//---------------------------------------------------------------------------//
