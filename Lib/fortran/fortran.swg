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
   %fortranspec    : Add specifications (public, variables) to a module
   %fortrancode    : Add proxy code to a module
 */

#define %fortranprepend       %feature("fortranprepend")
#define %clearfortranprepend  %feature("fortranprepend","")

#define %fortranappend         %feature("fortranappend")
#define %clearfortranappend    %feature("fortranappend","")

#define %fortranspec           %insert("fortranspec")

#define %fortrancode           %insert("fortran")

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
// CUSTOM TYPEMAP DESCRIPTIONS.

%include "fortypemaps.swg"

//---------------------------------------------------------------------------//
// RESERVED KEYWORDS
%include "forkw.swg"

//---------------------------------------------------------------------------//
// FRAGMENTS
%include "forfragments.swg"

//---------------------------------------------------------------------------//
// RUNTIME
%include "forruntime.swg"

//---------------------------------------------------------------------------//
// end of fortran/fortran.swg
//---------------------------------------------------------------------------//
