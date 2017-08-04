//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   simple_class/simple.i
 * \author Seth R Johnson
 * \date   Thu Dec 01 15:07:35 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module simple_class

%{
#include "SimpleClass.hh"
%}

#ifdef SWIGFORTRAN

%fortranappend SimpleClass::SimpleClass %{
   write(0, "(a, z16)") "F Constructed ", self%swigptr
%}
%fortranprepend SimpleClass::~SimpleClass %{
   write(0, "(a, z16)") "F Releasing   ", self%swigptr
%}
#endif

// %ignore make_class;
// %ignore get_class;

// %rename(SimpleClassDerp) SimpleClass;
%include "SimpleClass.hh"

// Overloaded instantiation
// %template(action) SimpleClass::action<double>;
// %template(action) SimpleClass::action<int>;

//---------------------------------------------------------------------------//
// end of simple_class/simple.i
//---------------------------------------------------------------------------//
