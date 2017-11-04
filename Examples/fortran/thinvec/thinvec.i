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

// Instantiate view to integers/double
%include <typemaps.i>
%fortran_view(int)
%fortran_view(double)

// Handle constructor overloading
%rename(create_count)  ThinVec::ThinVec(size_type);
%rename(create_fill)   ThinVec::ThinVec(size_type, value_type);

// Rename a function that's the same as a Fortran keyword
%rename(assign_from) ThinVec::assign;

// Handle the case of operator overloading
%rename(resize_fill) ThinVec::resize(size_type, value_type);

// Ignore return of types we don't understand (to prevent a warning)
%ignore ThinVec::data() const;

//---------------------------------------------------------------------------//
// Create a typemap that subtracts one from the given indices
//---------------------------------------------------------------------------//
#define PAIR_T std::pair<const int*, std::size_t>
#define THINVEC_T const ThinVec<int>& INDICES

// For vectors with the "INDICES" variable name, use *views* for the interface
%typemap(ctype)    THINVEC_T = PAIR_T;
%typemap(imtype)   THINVEC_T = PAIR_T;
%typemap(imimport) THINVEC_T = PAIR_T;

// Declare temporary variables
%typemap(findecl) THINVEC_T
%{
  integer(C_INT), dimension(:), pointer :: view$1
  integer(C_INT), allocatable, target, dimension(:) :: temp$1
  integer :: i$1
  integer :: sz$1
%}

// Implement transformation before the wrapper call
%typemap(fin) THINVEC_T
%{
  view$1 => $input%view()
  sz$1 = size(view$1)
  allocate(temp$1(sz$1))
  do i$1=1,sz$1
    temp$1(i$1) = view$1(i$1) + 1
  enddo
  $1%data = c_loc(temp$1)
  $1%size = size(temp$1)
%}

// Free temporary memory after function call
%typemap(ffreearg) THINVEC_T
%{
  deallocate(temp$1)
%}

// Since the C function call actually takes a ThinVec as an argument (not a
// view), we have to translate back
%typemap(in) THINVEC_T (ThinVec<int> tempvec)
%{
    tempvec.assign(std::make_pair($input->data, $input->size));
    $1 = &tempvec;
%}
//%typemap(arginit, noblock=1) const ThinVec<int>& INDICES;

#undef THINVEC_T
#undef PAIR_T

//---------------------------------------------------------------------------//

// Load the thinvec class definition
%include "ThinVec.hh"

// Instantiate
%template(ThinVecDbl) ThinVec<double>;
%template(ThinVecInt) ThinVec<int>;

%template(print_vec) print_vec<double>;
%template(print_vec) print_vec<int>;

//---------------------------------------------------------------------------//
// end of swig-dev/thinvec/ThinVec.i
//---------------------------------------------------------------------------//
