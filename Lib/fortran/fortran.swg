//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fortran.swg
 * \author Seth R Johnson
 * \date   Sat Dec 03 09:10:31 2016
 * \brief  Fortran typemap code
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

//---------------------------------------------------------------------------//
/*! LANGUAGE EXTENSIONS.

   %fortranprepend : Add code before the C++ function is called
   %fortranappend  : Add code after the C++ function is called
 */

#define %fortranprepend       %feature("fortranprepend")
#define %clearfortranprepend  %feature("fortranprepend","")

#define %fortranappend         %feature("fortranappend")
#define %clearfortranappend    %feature("fortranappend","")

//---------------------------------------------------------------------------//
/*! CUSTOM TYPEMAP DESCRIPTIONS.
 *
 * ctype : type in C wrapper code (input parameter, default return value)
 * ctype:out : *return* type (overrides ctype)
 * imtype : Fortran type in interface code (equivalent to C argument type)
 * imtype:out : Fortran return type in interface code (overrides imtype)
 * ftype  : Fortran proxy (shadow) code type
 * fxget   : Code used in proxy 'call' argument to convert proxy code type to
 *           interface type
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
 * - We can't return by reference-value in Fortran; you'll get a build-time
 *   error in your wrapper code if you try.
 * - Returning by const reference is automatically turned into return-by-value.
 */
%define FORTRAN_TYPEMAP(CTYPE, FTYPE)
  %typemap(ctype, out="CTYPE") CTYPE, CTYPE*, CTYPE& %{CTYPE*%}

  %typemap(in)      CTYPE                 %{$1 = *$input;%}
  %typemap(in)             CTYPE*, CTYPE& %{$1 = $input;%}

  %typemap(out)     CTYPE, const CTYPE* %{$result = $1;%}
  %typemap(out)            const CTYPE& %{$result = *$1;%}
  %typemap(out)            CTYPE& %{
    #error "Can't return by mutable reference in Fortran"
  %}

  %typemap(imtype)   CTYPE, CTYPE*, CTYPE& FTYPE
  %typemap(ftype)    CTYPE, CTYPE*, CTYPE& FTYPE
  %typemap(fxget)    CTYPE, CTYPE*, CTYPE& %{$1%}
%enddef

FORTRAN_TYPEMAP(bool       , "logical(C_BOOL)"     )
FORTRAN_TYPEMAP(char       , "character(C_CHAR)"   )
FORTRAN_TYPEMAP(short      , "integer(C_SHORT)"    )
FORTRAN_TYPEMAP(int        , "integer(C_INT)"      )
FORTRAN_TYPEMAP(long       , "integer(C_LONG)"     )
FORTRAN_TYPEMAP(long long  , "integer(C_LONG_LONG)")
FORTRAN_TYPEMAP(size_t     , "integer(C_SIZE_T)"   )
FORTRAN_TYPEMAP(float      , "real(C_FLOAT)"       )
FORTRAN_TYPEMAP(double     , "real(C_DOUBLE)"      )

// Apply
%apply char   { signed char, unsigned char };
%apply short  { unsigned short };
%apply int    { unsigned int };
%apply long   { unsigned long };
%apply size_t { unsigned long long };

// Instead of applying chars specifically, could do:
// FORTRAN_TYPEMAP(signed char, "integer(C_SIGNED_CHAR)")

//---------------------------------------------------------------------------//
// VOID TYPES
//---------------------------------------------------------------------------//
%typemap(ctype) void %{void%}
%typemap(out)     void %{%}
%typemap(imtype) void ""
%typemap(ftype)  void ""

//---------------------------------------------------------------------------//
// POINTER/CLASS TYPES
//---------------------------------------------------------------------------//

%typemap(in)      SWIGTYPE* %{ $1 = ($1_ltype)($input); %}
%typemap(in)      SWIGTYPE& %{ $1 = ($1_ltype)($input); assert($1); %}
%typemap(out)     SWIGTYPE*, const SWIGTYPE& %{ $result = $1; %}
%typemap(ctype)  SWIGTYPE*, SWIGTYPE&  %{void*%}
%typemap(imtype, out="type(C_PTR)") SWIGTYPE*, SWIGTYPE& "type(C_PTR), value"
%typemap(ftype)  SWIGTYPE*, SWIGTYPE&  "class($fortranclassname)"
%typemap(fxget)    SWIGTYPE*, SWIGTYPE&  "$1%ptr"

// Type checking on pointers
%{
#include <cassert>
%}
%typecheck(SWIG_TYPECHECK_POINTER)
   SWIGTYPE,
   SWIGTYPE*,
   SWIGTYPE&,
   SWIGTYPE&&,
   const SWIGTYPE&,
   SWIGTYPE[],
   SWIGTYPE(CLASS::*)
   ""

//---------------------------------------------------------------------------//
// end of fortran/fortran.swg
//---------------------------------------------------------------------------//
