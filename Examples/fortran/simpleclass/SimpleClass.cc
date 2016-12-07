//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   simple_class/SimpleClass.cc
 * \author Seth R Johnson
 * \date   Thu Dec 01 15:07:23 2016
 * \brief  SimpleClass class definitions.
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#include "SimpleClass.hh"

#include <iostream>
using std::cout;
using std::endl;

//---------------------------------------------------------------------------//
namespace
{
SimpleClass g_globalclass;
}

//---------------------------------------------------------------------------//
SimpleClass::SimpleClass()
    : d_storage(-1)
{
    cout << "Constructing at " << this << endl;
}

SimpleClass::SimpleClass(const SimpleClass& rhs)
    : d_storage(rhs.d_storage + 10)
{
    cout << "Copy-constructing " << rhs.get() << "=>" << get()
         << " at " << this << endl;
}

SimpleClass::SimpleClass(double d)
    : d_storage(d)
{
    cout << "Constructing " << get() << " at " << this << endl;
}

SimpleClass::~SimpleClass()
{
    cout << "Destroying   " << get() << " at " << this << endl;
}

void SimpleClass::set(storage_type val)
{
    d_storage = val;
    // throw std::logic_error("why did you set me");
}

void SimpleClass::double_it()
{
    d_storage *= 2;
}

SimpleClass::storage_type SimpleClass::get() const
{
    return d_storage;
}

SimpleClass::storage_type SimpleClass::get_multiplied(int multiple) const
{
    return d_storage * multiple;
}

//---------------------------------------------------------------------------//
void print_value(const SimpleClass& c)
{
    cout << "Simpleclass at " << &c << " has value " << c.get() << endl;
}

//---------------------------------------------------------------------------//
void dumb_copy(SimpleClass c)
{
    cout << "Copied: ";
    print_value(c);
}

//---------------------------------------------------------------------------//
SimpleClass make_class(double val)
{
    return SimpleClass(val);
}

void set_class_by_copy(SimpleClass c)
{
    g_globalclass = c;
}

const SimpleClass& get_class()
{
    return g_globalclass;
}


//---------------------------------------------------------------------------//
// end of simple_class/SimpleClass.cc
//---------------------------------------------------------------------------//
