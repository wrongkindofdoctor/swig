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
// CUSTOM TYPEMAP DESCRIPTIONS.

%include "fortrantypemaps.swg"

//---------------------------------------------------------------------------//
// RESERVED KEYWORDS
%include "fortrankw.swg"

//---------------------------------------------------------------------------//
// EXCEPTION SUPPORT
%include <exception.i>

//---------------------------------------------------------------------------//
// end of fortran/fortran.swg
//---------------------------------------------------------------------------//
