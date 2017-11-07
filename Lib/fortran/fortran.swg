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
   %fortrancode : Insert proxy code into a module
   %fortranprepend : Add code at the beginning of a proxy function
   %fortranappend  : Add code at the end of a proxy function
 */
#define %fortranprepend       %feature("fortranprepend")
#define %clearfortranprepend  %feature("fortranprepend","")

#define %fortranappend         %feature("fortranappend")
#define %clearfortranappend    %feature("fortranappend","")

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
// RESERVED KEYWORDS
%include "forkw.swg"

//---------------------------------------------------------------------------//
// RUNTIME
%include "forruntime.swg"

//---------------------------------------------------------------------------//
// end of fortran/fortran.swg
//---------------------------------------------------------------------------//
