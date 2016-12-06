//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortrantypemaps.swg
 * \author Seth R Johnson
 * \date   Sat Dec 03 09:10:31 2016
 * \brief  Fortran typemap code
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

//---------------------------------------------------------------------------//
/*! CUSTOM TYPEMAP DESCRIPTIONS.
 *
 * ctype : type in C wrapper code (input parameter, default return value)
 * ctype:out : *return* type (overrides ctype)
 * imtype : Fortran type in interface code (equivalent to C argument type)
 * imtype:out : Fortran return type in interface code (overrides imtype)
 * ftype  : Fortran proxy (shadow) code type
 * fin : Fortran proxy code used to translate a Fortan argument to a wrapper
 *       argument
 * fin:pre : Proxy code inserted before the wrapper call
 * fin:post : Proxy code inserted after the wrapper call
 */

//---------------------------------------------------------------------------//
// FUNDAMENTAL TYPES
//---------------------------------------------------------------------------//
/*!
 * \def FORTRAN_TYPEMAP
 * \brief Add a typemap for a fundamental built-in type.
 *
 * Return types are passed by value. Argument types in Fortran must be pointers
 * (so \c ctype is a pointer, and we use a \c typemap(in) to dereference the
 * argument).
 *
 * - We can't return mutable references in Fortran; you'll get a build-time
 *   error in your wrapper code if you try. Const references will get converted
 *   into values for fundamental types.
 * - Returning by const reference is automatically turned into return-by-value.
 *   (this is the 'out=CTYPE' argument)
 */
%define FORTRAN_TYPEMAP(CTYPE, FTYPE)
  %typemap(ctype, out="CTYPE") CTYPE, CTYPE*, CTYPE& %{CTYPE*%}

  %typemap(in) CTYPE          %{$1 = *$input;%}
  %typemap(in) CTYPE*, CTYPE& %{$1 = $input;%}

  %typemap(out) CTYPE, const CTYPE* %{$result = $1;%}
  %typemap(out) const CTYPE&        %{$result = *$1;%}
  %typemap(out) CTYPE& %{
    #error "Can't return by mutable reference in Fortran"
  %}

  // Note: FTYPE is a string, it gets preprocessor-concatenated to the
  // dimension/intent string
  %typemap(imtype)       CTYPE*  FTYPE ", dimension(*), intent(inout)"
  %typemap(imtype) const CTYPE*  FTYPE ", dimension(*), intent(in)"
  %typemap(imtype)       CTYPE&  FTYPE ", intent(inout)"
  %typemap(imtype, out=FTYPE) CTYPE, const CTYPE&  FTYPE ", intent(in)"

  %typemap(ftype)        CTYPE*  FTYPE ", dimension(:), intent(inout)"
  %typemap(ftype)  const CTYPE*  FTYPE ", dimension(:), intent(in)"
  %typemap(ftype)        CTYPE&  FTYPE ", intent(inout)"
  %typemap(ftype,  out=FTYPE) CTYPE, const CTYPE&  FTYPE ", intent(in)"

  %typemap(fin)  CTYPE, CTYPE*, CTYPE&, const CTYPE*, const CTYPE& %{$1_name%}
%enddef

FORTRAN_TYPEMAP(bool       , "logical(C_BOOL)"     )
FORTRAN_TYPEMAP(short      , "integer(C_SHORT)"    )
FORTRAN_TYPEMAP(int        , "integer(C_INT)"      )
FORTRAN_TYPEMAP(long       , "integer(C_LONG)"     )
FORTRAN_TYPEMAP(long long  , "integer(C_LONG_LONG)")
FORTRAN_TYPEMAP(size_t     , "integer(C_SIZE_T)"   )
FORTRAN_TYPEMAP(float      , "real(C_FLOAT)"       )
FORTRAN_TYPEMAP(double     , "real(C_DOUBLE)"      )

// Apply unsigned equivalent types
%apply short  { unsigned short };
%apply int    { unsigned int };
%apply long   { unsigned long };
%apply size_t { unsigned long long, std::size_t };

// Instead of applying chars specifically, could do:
// FORTRAN_TYPEMAP(signed char, "integer(C_SIGNED_CHAR)")

//---------------------------------------------------------------------------//
// VOID TYPES
//---------------------------------------------------------------------------//

%typemap(ctype)  void %{void%}
%typemap(out)    void %{%}
%typemap(imtype) void ""
%typemap(ftype)  void ""

//---------------------------------------------------------------------------//
// POINTER/CLASS TYPES
//---------------------------------------------------------------------------//

%typemap(ctype)  SWIGTYPE*, SWIGTYPE&  %{void*%}
%typemap(in)     SWIGTYPE*, SWIGTYPE& %{ $1 = ($1_ltype)($input); %}
%typemap(out)    SWIGTYPE*, const SWIGTYPE& %{ $result = $1; %}
%typemap(imtype, out="type(C_PTR)") SWIGTYPE*, SWIGTYPE& "type(C_PTR), value"
%typemap(ftype)  SWIGTYPE*, SWIGTYPE&  "class($fortranclassname)"
%typemap(fin)    SWIGTYPE*, SWIGTYPE&  "$1_name%ptr"

//---------------------------------------------------------------------------//
// ARRAY TYPES
//---------------------------------------------------------------------------//

// Cast integer to size_t whenever it shows up as a 'count' argument
%apply int { (std::size_t SIZE) };

// Automatically add "size" parameter from a Fortran array
%typemap(fin, noblock=1) (SWIGTYPE* ARRAY, int SIZE)
    { $1_name, size($1_name) }
%apply (SWIGTYPE* ARRAY, int SIZE) { (SWIGTYPE* ARRAY, int SIZE),
                                     (const SWIGTYPE* ARRAY, int SIZE) };

//---------------------------------------------------------------------------//
// STRING TYPES
//---------------------------------------------------------------------------//

// Single characters: differentiate from char pointers by using value semantics
%typemap(ctype, out="char") char %{char*%}
%typemap(in)    char %{ $1 = *$input; %}
%typemap(out)   char %{ $result = $1; %}
%typemap(imtype, out="character") char "character, value"
%typemap(ftype,  out="character") char "character, value, intent(in)"
%typemap(fin) char "$1_name"

%typemap(ctype)  char* %{ char* %}
%typemap(in)     char* %{ $1 = $input; %}
%typemap(imtype) char* "character(C_CHAR)"
%typemap(ftype)  char* "character(len=*)"
%typemap(fin)    char* "$1_name"

// Automatically add "size" parameter from a Fortran array
%typemap(fin, noblock=1) (char* STRING, int SIZE)
{ $1_name, len($1_name) }

//---------------------------------------------------------------------------//
// end of fortran/fortrantypemaps.swg
//---------------------------------------------------------------------------//
