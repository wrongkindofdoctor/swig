//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/typemaps.i
 * \author Seth R Johnson
 * \date   Tue May 09 14:50:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//


//---------------------------------------------------------------------------//
// STRING TYPES
//
// Note that currently strings can be passed as character arrays, but returning
// a C string gives just an opaque C pointer
//---------------------------------------------------------------------------//

%define CHAR_TYPEMAP(CTYPE)
    %typemap(fin, noblock=1) (CTYPE* STRING, int SIZE)
    { $1_name, len($1_name) }
%enddef

CHAR_TYPEMAP(const char)
CHAR_TYPEMAP(char)
CHAR_TYPEMAP(unsigned char)
CHAR_TYPEMAP(const unsigned char)

#undef CHAR_TYPEMAP

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
// end of fortran/typemaps.i
//---------------------------------------------------------------------------//
