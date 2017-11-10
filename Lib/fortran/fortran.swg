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
   %fortranprepend : Add code at the beginning of a proxy function
   %fortranappend  : Add code at the end of a proxy function

   %parameter : Force a global constant to be treated as a compile-time value
           (value MUST be interpretable by Fortran)
   %enumerator : Force an enum to be treated as a compile-time Fortran enum
           (enum values MUST be interpretable by Fortran)
 */
#define %fortranprepend       %feature("fortranprepend")
#define %clearfortranprepend  %feature("fortranprepend","")

#define %fortranappend         %feature("fortranappend")
#define %clearfortranappend    %feature("fortranappend","")

#define %parameter      %feature("parameter")
#define %noparameter    %feature("parameter","0")
#define %clearparameter %feature("parameter","")

#define %enumerator      %feature("enumerator")
#define %noenumerator    %feature("enumerator","0")
#define %clearenumerator %feature("enumerator","")

//---------------------------------------------------------------------------//
// STANDARD TYPE DEFINITIONS

#ifdef __cplusplus
namespace std
{
#endif
typedef unsigned long size_t;
typedef long ptrdiff_t;
#ifdef __cplusplus
}
using std::size_t;
using std::ptrdiff_t;
#endif

//---------------------------------------------------------------------------//
// FRAGMENTS
%include "forfragments.swg"

//---------------------------------------------------------------------------//
// CUSTOM TYPEMAP DESCRIPTIONS.
%include "fortypemaps.swg"

//---------------------------------------------------------------------------//
// ENUMERATOR OVERRIDES
%include "fortypemaps.swg"

//---------------------------------------------------------------------------//
// RESERVED KEYWORDS
%include "forkw.swg"

//---------------------------------------------------------------------------//
// RUNTIME
%include "forruntime.swg"

//---------------------------------------------------------------------------//
// end of fortran/fortran.swg
//---------------------------------------------------------------------------//
