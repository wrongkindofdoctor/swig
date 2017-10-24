//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   std_vector/stdvec.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 09:05:31 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%module stdvec

%{
#include <utility>
#include "stdvec.hh"
%}

namespace std
{
template<typename T1,typename T2>
struct pair
{
};
}

// %include <std_vector.i>
// %template(VecDbl) std::vector<double>;

//---------------------------------------------------------------------------//

// Add array wrapper to C++ code when used by Fortran fragment
%fragment("SwigfArrayWrapper_cpp", "header") %{
namespace swig {
template<class T>
struct SwigfArrayWrapper
{
    T* data;
    std::size_t size;
};
}
%}

// Add array wrapper to Fortran types when used
%fragment("SwigfArrayWrapper", "ftypes", fragment="SwigfArrayWrapper_cpp",
          noblock="1") %{
type, public, bind(C) :: SwigfArrayWrapper
  type(C_PTR), public :: data
  integer(C_SIZE_T), public :: size
end type
%}

%define FORT_POINTER_TYPEMAP(CTYPE, FTYPE)
  #define PAIR_TYPE std::pair< CTYPE*, CTYPE* >
  #define AW_TYPE swig::SwigfArrayWrapper< CTYPE >
  #define QAW_TYPE "swig::SwigfArrayWrapper<" #CTYPE ">"

  %template() PAIR_TYPE;

  // C wrapper type: pointer to templated array wrapper
  %typemap(ctype, noblock=1, out=QAW_TYPE,
           fragment="SwigfArrayWrapper") PAIR_TYPE
    {AW_TYPE*}

  // C input translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(in) PAIR_TYPE
    %{$1.first = $input->data;
      $1.second = $1.first + $input->size;%}

  // C output initialization
  %typemap(arginit) AW_TYPE
    %{$1.data = NULL;
      $1.size = 0;%}

  // C output translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(out) PAIR_TYPE
    %{$result.data = $1.first;
      $result.size = $1.second - $1.first;%}

  // Interface type: fortran equivalent of "ctype"
  // Optional "in" is for when it's an argument of the wrapper declaration; the
  // main typemap `type(SwigfArrayWrapper)` is used as a temporary variable
  // in the fortran proxy code
  %typemap(imimport, fragment="SwigfArrayWrapper") PAIR_TYPE
    "SwigfArrayWrapper"
  %typemap(imtype, in="type(SwigfArrayWrapper), intent(inout)") PAIR_TYPE
     "type(SwigfArrayWrapper)"

  // Fortran proxy code: "out" is when it's a return value;
  // the main type is when it's an input value
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") PAIR_TYPE
    FTYPE ", dimension(:), target, intent(inout)"

  // Fortran proxy translation code: convert from ftype $input to imtype $1
  %typemap(fin) PAIR_TYPE
    %{$1%data = c_loc($input)
      $1%size = size($input)%}

  // Fortran proxy translation code: convert from imtype 1 to ftype $result
  %typemap(fout) PAIR_TYPE
  %{
      call c_f_pointer($1%data, $result, [$1%size])
  %}
%enddef

//---------------------------------------------------------------------------//
// Instantiate a view template and add a "view" method.
//---------------------------------------------------------------------------//

FORT_POINTER_TYPEMAP(const double, "real(C_DOUBLE)")

//---------------------------------------------------------------------------//

%include "stdvec.hh"

//---------------------------------------------------------------------------//

%template(make_const_ptrdbl) make_const_ptr<double>;
%template(print_ptrdbl) print_ptr<double>;

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.i
//---------------------------------------------------------------------------//
