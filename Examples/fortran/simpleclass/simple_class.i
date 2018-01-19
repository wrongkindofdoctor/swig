//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   simple_class/simple.i
 * \author Seth R Johnson
 * \date   Thu Dec 01 15:07:35 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module(docstring="A simple example module") simple_class

%include "docstring.i"

%{
#include "SimpleClass.hh"
%}

%{
#include <iostream>
using std::cout;
using std::endl;
%}

%fortranbegin %{
! This code is injected immediately below the SWIG auto-generated comment
%}

%inline %{
void print_pointer(int msg, const SimpleClass* ptr)
{
    cout << "F " << (msg == 0 ? "Constructed"
                   : msg == 1 ? "Releasing"
                   : msg == 2 ? "Assigning from"
                   : msg == 3 ? "Assigning to"
                              : "XXX"
                     )
        << ' ' << (ptr ? ptr->id() : -1) << endl;
}
%}


/*
 * Note: this used to be: \code
    write(0, "(a, z16)") "F Constructed ", self%swigptr
 * \endcode
 *
 * but printing pointers is not standards-compliant.
 */

%fortranappend SimpleClass::SimpleClass %{
    call print_pointer(0, self)
%}
%fortranprepend SimpleClass::~SimpleClass %{
    call print_pointer(1, self)
%}

// %ignore make_class;
// %ignore get_class;

%feature("docstring") SimpleClass %{
Simple test class.

C++ includes: SimpleClass.hh
%};

%feature("docstring")  SimpleClass::double_it %{
void SimpleClass::double_it()

Multiply the value by 2.
%};

//%rename(assign) SimpleClass::operator=;

%extend SimpleClass {

void assign(const SimpleClass& other)
{
    *$self = other;
}

%insert("ftypes") %{
  procedure, private :: assign_simpleclass_impl
  generic :: assignment(=) => assign_simpleclass_impl
%}

%insert("fwrapper") %{
subroutine assign_simpleclass_impl(self, other)
    use, intrinsic :: ISO_C_BINDING
    class(SimpleClass), intent(inout) :: self
    class(SimpleClass), intent(in) :: other
    call print_pointer(2, other)
    call print_pointer(3, self)
    if (self%swigdata%flag == SWIGF_OWNER) then
      call swigc_SimpleClass_assign(self%swigdata, other%swigdata)
    else
      call self%create(other)
    endif
end subroutine
%}

};

%feature("new") emit_class;

// Make BasicStruct a fortran-accessible struct.
%fortran_bindc_struct(BasicStruct);

%include "SimpleClass.hh"

// Overloaded instantiation
%template(action) SimpleClass::action<double>;
%template(action) SimpleClass::action<int>;

//---------------------------------------------------------------------------//
// end of simple_class/simple.i
//---------------------------------------------------------------------------//
