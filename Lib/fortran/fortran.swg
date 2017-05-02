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
// CUSTOM TYPEMAP DESCRIPTIONS.

%include "fortrantypemaps.swg"

//---------------------------------------------------------------------------//
// RESERVED KEYWORDS
%include "fortrankw.swg"

//---------------------------------------------------------------------------//
// FRAGMENTS
%include "fragments.swg"

//---------------------------------------------------------------------------//
// RUNTIME
%include "fortranruntime.swg"

//---------------------------------------------------------------------------//
// end of fortran/fortran.swg
//---------------------------------------------------------------------------//
