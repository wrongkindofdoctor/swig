//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/typemaps.i
 * \author Seth R Johnson
 * \date   Tue May 09 14:50:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

//---------------------------------------------------------------------------//
// ARRAY VIEWS
//
// This maps a return value of pair<T*,size_t> to a small struct (mirrored in
// fortran) that defines the start and size of a contiguous array.
//---------------------------------------------------------------------------//
%define FORT_VIEW_TYPEMAP_IMPL(FTYPE, CONST_CTYPE...)
  %include <std_pair.i>

  #define SWIGPAIR__ ::std::pair< CONST_CTYPE*, std::size_t >

  // C wrapper type: pointer to templated array wrapper
  %typemap(ctype, noblock=1,
           out="SwigfArrayWrapper",
           null="SwigfArrayWrapper_uninitialized()",
           fragment="SwigfArrayWrapper_wrap") SWIGPAIR__
    {SwigfArrayWrapper*}

  // C input translation typemaps: $1 is SWIGPAIR__, $input is SwigfArrayWrapper
  %typemap(in) SWIGPAIR__
    %{$1.first  = static_cast<CONST_CTYPE*>($input->data);
      $1.second = $input->size;%}

  // C output translation typemaps
  %typemap(out) SWIGPAIR__
    %{$result.data = $1.first;
      $result.size = $1.second;%}

  // Interface type: fortran equivalent of "ctype"
  // Since the type is declared in the module, it's necessary to use the
  // fortran "import" statement to bring it into scope.
  %typemap(imtype, import="SwigfArrayWrapper",
           fragment="SwigfArrayWrapper") SWIGPAIR__
     "type(SwigfArrayWrapper)"

  // Fortran proxy code: "out" is when it's a return value;
  // the main type is when it's an input value
  %typemap(ftype, out=FTYPE ", dimension(:), pointer") SWIGPAIR__
    FTYPE ", dimension(:), target, intent(inout)"

  // Fortran proxy translation code: convert from ftype $input to imtype $1
  // Note that we take the address of the first element instead of the array,
  // because nonallocatable deferred-size arrays *cannot* be referenced in
  // standard F2003. This is because they might be slices of other arrays
  // (noncontiguous). It is the caller's responsibility to ensure only
  // contiguous arrays are passed. Conceivably we could improve this to use
  // strided access by also passing c_loc($input(2)) and doing pointer
  // arithmetic.
  %typemap(findecl) SWIGPAIR__
  FTYPE ", pointer :: $1_view"

  %typemap(fin) SWIGPAIR__
    %{$1_view => $input(1)
      $1%data = c_loc($1_view)
      $1%size = size($input)%}

  // Fortran proxy translation code: convert from imtype 1 to ftype $result
  %typemap(fout) SWIGPAIR__
  %{
      call c_f_pointer($1%data, $result, [$1%size])
  %}

  // Instantiate type so that SWIG respects %novaluewrapper
  %template() SWIGPAIR__;

  #undef SWIGPAIR__
%enddef

// Declare wrapper functions for std::pair<T*,size_t> and <const T*, ...>
%define FORT_VIEW_TYPEMAP(FTYPE, CTYPE)
    FORT_VIEW_TYPEMAP_IMPL(FTYPE, CTYPE)
    FORT_VIEW_TYPEMAP_IMPL(FTYPE, const CTYPE)

  // Add const cast to output
  %typemap(out) ::std::pair< const CTYPE*, std::size_t >
    %{$result.data = const_cast<CTYPE*>($1.first);
      $result.size = $1.second;%}
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
// wrapper code uses slightly different types. (To be strictly compatible with
// Fortran-C interoperability, only arrays of length-1 chars can be passed back
// and forth between C; we use a fragment in `forfragments.swg` to perform the
// remapping.
//---------------------------------------------------------------------------//

%define FORT_STRVIEW_TYPEMAP_IMPL(CHARTYPE, CONST_CTYPE...)
  FORT_VIEW_TYPEMAP_IMPL("character(kind=" CHARTYPE ")", CONST_CTYPE)
  #define SWIGPAIR__ ::std::pair< CONST_CTYPE*, std::size_t >

  // Fortran proxy code: accept a character string, but since we don't seem to
  // be able to get character string pointers, return as an array view.
  %typemap(ftype, out="character(kind=" CHARTYPE "), dimension(:), pointer") SWIGPAIR__
    "character(kind=" CHARTYPE ", len=*), target"

  %typemap(findecl) SWIGPAIR__
  %{
    character(kind=C_CHAR), dimension(:), allocatable, target :: $1_chars
  %}

  // Fortran proxy translation code: copy var-length character type to
  // fixed-length character array
  %typemap(fin, fragment="SwigfStringToCharArray", noblock=1) SWIGPAIR__
  %{
    call swigf_string_to_chararray($input, $1_chars, $1)
  %}

  #undef SWIGPAIR__
%enddef

// Declare wrapper functions for std::pair<T*,size_t> and <const T*, ...>
%define FORT_STRVIEW_TYPEMAP(CHARTYPE, CTYPE)
    FORT_STRVIEW_TYPEMAP_IMPL(CHARTYPE, CTYPE)
    FORT_STRVIEW_TYPEMAP_IMPL(CHARTYPE, const CTYPE)

  // Add const cast to output
  %typemap(out) ::std::pair< const CTYPE*, std::size_t >
    %{$result.data = const_cast<CTYPE*>($1.first);
      $result.size = $1.second;%}
%enddef

%define %fortran_string_view(CTYPE)
    // This is only here to mirror %fortran_view
    FORT_STRVIEW_TYPEMAP("C_CHAR", CTYPE)
%enddef

//---------------------------------------------------------------------------//
// Optional string typemaps for native fortran conversion.
// Currently because we don't have the interface to free a std::string that's
// returned with 'new' (or by value) we only support const references.
//
// Use:
//     %apply const std::string& NATIVE { const std::string& key };
//---------------------------------------------------------------------------//

// C wrapper type: pointer to templated array wrapper
%typemap(ctype, noblock=1, out="SwigfArrayWrapper",
       null="SwigfArrayWrapper_uninitialized()",
       fragment="SwigfArrayWrapper_wrap") std::string NATIVE
{SwigfArrayWrapper*}

// C input translation typemaps: $1 is std::string*, $input is SwigfArrayWrapper
%typemap(in) std::string NATIVE (std::string tempstr)
%{tempstr = std::string(static_cast<const char*>($input->data), $input->size);
$1 = &tempstr;
%}

// C output translation typemaps: $1 is string*, $input is SwigfArrayWrapper
%typemap(out) std::string NATIVE
%{#error "Currently cannot return strings by value as NATIVE strings" %}

%typemap(imtype, import="SwigfArrayWrapper") std::string NATIVE
 "type(SwigfArrayWrapper)"

// Fortran proxy code: return allocatable string
%typemap(ftype, out="character(kind=C_CHAR, len=:), allocatable")
    std::string NATIVE
  "character(kind=C_CHAR, len=*), target"

%typemap(findecl) std::string NATIVE
%{
character(kind=C_CHAR), dimension(:), allocatable, target :: $1_chars
%}
%typemap(fin, fragment="SwigfStringToCharArray", noblock=1) std::string NATIVE
%{
  call swigf_string_to_chararray($input, $1_chars, $1)
%}

// Fortran proxy translation code: convert from char array to Fortran string
%typemap(fout, fragment="SwigfCharArrayToString") std::string NATIVE
%{
  call swigf_chararray_to_string($1, $result)
%}

// RETURN BY CONST REFERENCE

%apply std::string NATIVE { const std::string* NATIVE,
                            const std::string& NATIVE };

// C output translation typemaps: $1 is string*, $input is SwigfArrayWrapper
%typemap(out) const std::string& NATIVE
%{$result.data = ($1->empty() ? NULL : &(*$1->begin()));
  $result.size = $1->size();
  %}

//---------------------------------------------------------------------------//
// end of fortran/typemaps.i
//---------------------------------------------------------------------------//
