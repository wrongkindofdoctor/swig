//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/typemaps.i
 * \author Seth R Johnson
 * \date   Tue May 09 14:50:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

//---------------------------------------------------------------------------//
// ARRAY TYPES
//
// This maps a return value of pair<T*,size_t> to a small struct (mirrored in
// fortran) that defines the start and size of a contiguous array.
//
//---------------------------------------------------------------------------//
%include <std_pair.i>

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
%fragment("SwigfArrayWrapper", "fpublic", fragment="SwigfArrayWrapper_cpp",
          noblock="1") %{
type, public, bind(C) :: SwigfArrayWrapper
  type(C_PTR), public :: data
  integer(C_SIZE_T), public :: size
end type
%}

%define FORT_VIEW_TYPEMAP_IMPL(FTYPE, CONST_CTYPE...)
  #define PAIR_TYPE ::std::pair< CONST_CTYPE*, size_t >
  #define AW_TYPE swig::SwigfArrayWrapper< CONST_CTYPE >
  // XXX: for some reason, using #define genereates a %constant and a warning
  %define QAW_TYPE
      "swig::SwigfArrayWrapper<" #CONST_CTYPE ">"
  %enddef

  // C wrapper type: pointer to templated array wrapper
  %typemap(ctype, noblock=1, out=QAW_TYPE,
           fragment="SwigfArrayWrapper") PAIR_TYPE
    {AW_TYPE*}

  // C input translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(arginit, noblock=1) PAIR_TYPE
    {$1 = PAIR_TYPE();}

  // C input translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(in) PAIR_TYPE
    %{$1.first  = $input->data;
      $1.second = $input->size;%}

  // C output initialization
  %typemap(arginit) AW_TYPE
    %{$1.data = NULL;
      $1.size = 0;%}

  // C output translation typemaps: $1 is PAIR_TYPE, $input is AW_TYPE
  %typemap(out) PAIR_TYPE
    %{$result.data = $1.first;
      $result.size = $1.second;%}

  // Interface type: fortran equivalent of "ctype"
  // Optional "in" is for when it's an argument of the wrapper declaration; the
  // main typemap `type(SwigfArrayWrapper)` is used as a temporary variable
  // in the fortran proxy code
  %typemap(imimport, fragment="SwigfArrayWrapper") PAIR_TYPE
    "SwigfArrayWrapper"
  %typemap(imtype, in="type(SwigfArrayWrapper)") PAIR_TYPE
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
  #undef PAIR_TYPE
  #undef AW_TYPE
  #undef QAW_TYPE
%enddef

// Declare wrapper functions for std::pair<T*,size_t> and <const T*, ...>
%define FORT_VIEW_TYPEMAP(FTYPE, CTYPE)
    FORT_VIEW_TYPEMAP_IMPL(FTYPE, CTYPE)
    FORT_VIEW_TYPEMAP_IMPL(FTYPE, const CTYPE)
%enddef

// Macro for defining the typemaps inside a class (e.g. std_vector to allow
// automatic view support), so that the fragments and typemaps are only used as
// needed
%define %fort_view_typemap(CTYPE)
    FORT_VIEW_TYPEMAP("$typemap(imtype, " #CTYPE ")", CTYPE)
%enddef

//---------------------------------------------------------------------------//
// STRING VIEWS
//
// String views are treated almost exactly like array views, except the Fortran
// wrapper code uses slightly different types.
//---------------------------------------------------------------------------//

%define FORT_STRVIEW_TYPEMAP_IMPL(FTYPE, CONST_CTYPE...)
  FORT_VIEW_TYPEMAP_IMPL(FTYPE, CONST_CTYPE)
  #define PAIR_TYPE ::std::pair< CONST_CTYPE*, size_t >

  // Fortran proxy code: accept a character string, but since we don't seem to
  // be able to get character string pointers, return as an array view.
  %typemap(ftype, out="character(kind=" FTYPE "), dimension(:), pointer") PAIR_TYPE
    "character(kind=" FTYPE ", len=*), target"

  // Fortran proxy translation code: convert from ftype $input to imtype $1
  %typemap(fin) PAIR_TYPE
    %{$1%data = c_loc($input)
      $1%size = len($input)%}

  #undef PAIR_TYPE
%enddef

// Declare wrapper functions for std::pair<T*,size_t> and <const T*, ...>
%define FORT_STRVIEW_TYPEMAP(FTYPE, CTYPE)
    FORT_STRVIEW_TYPEMAP_IMPL(FTYPE, CTYPE)
    FORT_STRVIEW_TYPEMAP_IMPL(FTYPE, const CTYPE)
%enddef

FORT_STRVIEW_TYPEMAP("C_CHAR", char)

//---------------------------------------------------------------------------//
// end of fortran/typemaps.i
//---------------------------------------------------------------------------//
