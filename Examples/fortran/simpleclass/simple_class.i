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

#if 0
// Insert assignment implementation
%fragment("SwigfClassAssign");

%extend SimpleClass {

%insert("ftypes") %{
  procedure, private :: swigf_SimpleClass_assign
  generic :: assignment(=) => swigf_SimpleClass_assign
%}

%insert("wrapper") %{
SWIGEXPORT void swigc_SimpleClass_assign(
        SwigfClassWrapper* farg1,
        SwigfClassWrapper* farg2)
{
    SWIGF_assign(SimpleClass, farg1, SimpleClass, farg2);
}
%}

%insert("finterfaces") %{
subroutine swigc_SimpleClass_assign(farg1, farg2) &
    bind(C, name="swigc_SimpleClass_assign")
    use, intrinsic :: ISO_C_BINDING
  import :: SwigfClassWrapper
  type(SwigfClassWrapper) :: farg1
  type(SwigfClassWrapper) :: farg2
end subroutine
%}

%insert("fwrapper") %{
subroutine swigf_SimpleClass_assign(self, other)
    use, intrinsic :: ISO_C_BINDING
    class(SimpleClass), intent(inout) :: self
    class(SimpleClass), intent(in) :: other
    call print_pointer(2, other)
    call print_pointer(3, self)
    call swigc_SimpleClass_assign(self%swigdata, other%swigdata)
    write(0,*) "New self state: ", self%swigdata%mem
end subroutine
%}

};
#endif

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
