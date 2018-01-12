//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/typemaps.i
 * \author Seth R Johnson
 * \date   Tue May 09 14:50:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <std_pair.i>

//---------------------------------------------------------------------------//
// ARRAY TYPES
//
// This maps a return value of pair<T*,size_t> to a small struct (mirrored in
// fortran) that defines the start and size of a contiguous array.
//
//---------------------------------------------------------------------------//
%define FORT_VIEW_TYPEMAP_IMPL(FTYPE, CONST_CTYPE...)
  #define PAIR_TYPE ::std::pair< CONST_CTYPE*, std::size_t >
  #define AW_TYPE swig::SwigfArrayWrapper< CONST_CTYPE >

  // C wrapper type: pointer to templated array wrapper
  %typemap(ctype, noblock=1, out=%str(swig::SwigfArrayWrapper< CONST_CTYPE >),
           null=%str(swig::SwigfArrayWrapper< CONST_CTYPE >()),
           fragment="SwigfArrayWrapper") PAIR_TYPE
    {AW_TYPE*}

  // C input initialization typemaps
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
  %typemap(imtype, in="type(SwigfArrayWrapper)") PAIR_TYPE
     "type(SwigfArrayWrapper)"
  // Since the SwigfArrayWrapper type is declared in the module, it's necessary
  // to "import" the variable in the interface declaration.
  %typemap(imimport, fragment="SwigfArrayWrapper") PAIR_TYPE
    "SwigfArrayWrapper"

  // Fortran proxy code: "out" is when it's a return value;
  // the main type is when it's an input value
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") PAIR_TYPE
    FTYPE ", dimension(:), target, intent(inout)"

  // Fortran proxy translation code: convert from ftype $input to imtype $1
  // Note that we take the address of the first element instead of the array,
  // because nonallocatable deferred-size arrays *cannot* be referenced in
  // standard F2003. This is because they might be slices of other arrays
  // (noncontiguous). It is the caller's responsibility to ensure only
  // contiguous arrays are passed. Conceivably we could improve this to use
  // strided access by also passing c_loc($input(2)) and doing pointer
  // arithmetic.
  %typemap(fin) PAIR_TYPE
    %{$1%data = c_loc($input(1))
      $1%size = size($input)%}

  // Instantiate type so that SWIG respects %novaluewrapper
  %template() PAIR_TYPE;

  // Fortran proxy translation code: convert from imtype 1 to ftype $result
  %typemap(fout) PAIR_TYPE
  %{
      call c_f_pointer($1%data, $result, [$1%size])
  %}
  #undef PAIR_TYPE
  #undef AW_TYPE
%enddef

// Declare wrapper functions for std::pair<T*,size_t> and <const T*, ...>
%define FORT_VIEW_TYPEMAP(FTYPE, CTYPE)
    FORT_VIEW_TYPEMAP_IMPL(FTYPE, CTYPE)
    FORT_VIEW_TYPEMAP_IMPL(FTYPE, const CTYPE)
%enddef

// Macro for defining the typemaps inside a class (e.g. std_vector to allow
// automatic view support), so that the fragments and typemaps are only used as
// needed
%define %fortran_view(CTYPE)
    FORT_VIEW_TYPEMAP("$typemap(imtype, " #CTYPE ")", CTYPE)
%enddef

//---------------------------------------------------------------------------//
// STRING VIEWS
//
// String views are treated almost exactly like array views, except the Fortran
// wrapper code uses slightly different types.
//---------------------------------------------------------------------------//

%define FORT_STRVIEW_TYPEMAP_IMPL(CHARTYPE, CONST_CTYPE...)
  FORT_VIEW_TYPEMAP_IMPL("character(kind=" CHARTYPE ")", CONST_CTYPE)
  #define PAIR_TYPE ::std::pair< CONST_CTYPE*, std::size_t >

  // Fortran proxy code: accept a character string, but since we don't seem to
  // be able to get character string pointers, return as an array view.
  %typemap(ftype, out="character(kind=" CHARTYPE "), dimension(:), pointer") PAIR_TYPE
    "character(kind=" CHARTYPE ", len=*), target"

%typemap(findecl) PAIR_TYPE
%{
 integer(kind=C_SIZE_T) :: $1_i
 character(kind=C_CHAR), dimension(:), allocatable, target :: $1_chars
%}

  // Fortran proxy translation code: copy var-length character type to
  // fixed-length character array
  %typemap(fin) PAIR_TYPE
  %{
  allocate(character(kind=C_CHAR) :: $1_chars(len($input)))
  do $1_i=1,size($1_chars)
    $1_chars($1_i) = $input($1_i:$1_i)
  enddo
  $1%data = c_loc($1_chars)
  $1%size = size($1_chars)
  %}

  // Free allocated memory
  %typemap(ffreearg) PAIR_TYPE
  %{
  deallocate($1_chars)
  %}

  #undef PAIR_TYPE
%enddef

// Declare wrapper functions for std::pair<T*,size_t> and <const T*, ...>
%define FORT_STRVIEW_TYPEMAP(CHARTYPE, CTYPE)
    FORT_STRVIEW_TYPEMAP_IMPL(CHARTYPE, CTYPE)
    FORT_STRVIEW_TYPEMAP_IMPL(CHARTYPE, const CTYPE)
%enddef

%define %fortran_string_view(CTYPE)
    // This is only here to mirror %fortran_view
    FORT_STRVIEW_TYPEMAP("C_CHAR", CTYPE)
%enddef

//---------------------------------------------------------------------------//
// end of fortran/typemaps.i
//---------------------------------------------------------------------------//
