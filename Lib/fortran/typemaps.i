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
  #define AW_TYPE SwigfArrayWrapper< CONST_CTYPE >

  // C wrapper type: pointer to templated array wrapper
  %typemap(ctype, noblock=1,
           out={SwigfArrayWrapper< CONST_CTYPE >},
           null={SwigfArrayWrapper< CONST_CTYPE >()},
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
  // Since the type is declared in the module, it's necessary to use the
  // fortran "import" statement to bring it into scope.
  %typemap(imtype, import="SwigfArrayWrapper") PAIR_TYPE
     "type(SwigfArrayWrapper)"

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
  %typemap(findecl) PAIR_TYPE
  FTYPE ", pointer :: $1_view"

  %typemap(fin) PAIR_TYPE
    %{$1_view => $input(1)
      $1%data = c_loc($1_view)
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
    character(kind=C_CHAR), dimension(:), allocatable, target :: $1_chars
  %}

  // Fortran proxy translation code: copy var-length character type to
  // fixed-length character array
  %typemap(fin, fragment="SwigfStringToCharArray", noblock=1) PAIR_TYPE
  %{
    call swigf_string_to_chararray($input, $1_chars, $1)
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
