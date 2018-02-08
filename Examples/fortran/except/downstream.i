//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   except/downstream.i
 * \author Seth R Johnson
 * \date   Wed Nov 01 12:54:00 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module downstream;

%import "except.i"

%inline %{
void throw_error()
{
    throw std::logic_error("Threw an error for you");
}
%}

//---------------------------------------------------------------------------//
// end of exceptions/downstream.i
//---------------------------------------------------------------------------//
