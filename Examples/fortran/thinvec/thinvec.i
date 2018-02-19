/* File : thinvec.i */
%{
#include "ThinVec.h"
%}

%module thinvec

%include <typemaps.i>
%fortran_view(int)
%fortran_view(double)

// Ignore return of types we don't understand (to prevent a warning)
%ignore ThinVec::data() const;

/* -------------------------------------------------------------------------
 * Note: since we use %const_cast and %static_cast, which are SWIG-defined

 *  temporary variable (called tempvec) declared in the parentheses.
%typemap(in, noblock=1) const ThinVec<int>& INDICES (ThinVec<int> tempvec)
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

// Load the thinvec class definition
%include "ThinVec.h"

// Instantiate classes
%template(ThinVecDbl) ThinVec<double>;
%template(ThinVecInt) ThinVec<int>;

// Instantiate functions
%template(print_vec) print_vec<double>;
%template(print_vec) print_vec<int>;


/* vim: set ts=2 sw=2 sts=2 tw=129 : */
