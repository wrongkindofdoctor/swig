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

%fragment("Swigf_ArrayWrapper", "header") %{
namespace swig {
template<class T>
struct Swigf_ArrayWrapper
{
    T* data;
    std::size_t size;
};
}
%}

// XXX maybe just declare the C class to wrap??
%fragment("Swigf_ArrayWrapper", "fortranspec") %{
type, public, bind(C) :: Swigf_ArrayWrapper
  type(C_PTR), public :: data
  integer(C_SIZE_T), public :: size
end type
%}

%define FORT_POINTER_TYPEMAP(CTYPE, FTYPE)
  #define PAIR_TYPE std::pair< CTYPE*, CTYPE* >
  #define AW_TYPE swig::Swigf_ArrayWrapper< CTYPE >
  #define QAW_TYPE "swig::Swigf_ArrayWrapper<" #CTYPE ">"

  %template() PAIR_TYPE;

  // C wrapper type: pointer to templated array wrapper
  %typemap(ctype, noblock=1, out=QAW_TYPE,
           fragment="Swigf_ArrayWrapper") PAIR_TYPE
    {AW_TYPE*}
  // C input translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(in) PAIR_TYPE
    %{$1.first = $input->data;
      $1.second = $1.first + $input->size%}
  // C output translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(out) PAIR_TYPE
    %{$result.data = $1.first;
      $result.size = $1.second - $1.first;%}
  // Interface type: fortran equivalent of "ctype"
  // Optional "in" is for when it's an argument of the wrapper declaration; the
  // main typemap `type(Swigf_ArrayWrapper)` is used as a temporary variable
  // in the fortran proxy code
  %typemap(imtype, in="import :: Swigf_ArrayWrapper\n"
           "type(Swigf_ArrayWrapper), intent(inout)") PAIR_TYPE
    "import :: Swigf_ArrayWrapper\n""type(Swigf_ArrayWrapper)"
  // Fortran proxy code: "out" is when it's a return value;
  // the main type is when it's an input value
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") PAIR_TYPE
    FTYPE ", dimension(:), intent(inout)"
  // Fortran proxy translation code: convert from ftype $input to imtype $1
  %typemap(fin) PAIR_TYPE
    %{$1%data = c_loc($input)
      $1%size = size($input)%}
  // Fortran proxy translation code: convert from imtype 1 to ftype $result
  %typemap(fout) PAIR_TYPE
  %{
      call c_f_pointer(c_loc($1%data), $result, [$1%size])
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
