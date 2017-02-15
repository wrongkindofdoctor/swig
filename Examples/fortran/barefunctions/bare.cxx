//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   bare_function/bare.cc
 * \author Seth R Johnson
 * \date   Wed Nov 30 17:45:22 2016
 * \brief  bare implementation
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#include "bare.hh"

#include <stdexcept>
#include <iostream>
using std::cout;
using std::endl;

namespace
{
double data[10];
}

void set_something(int x, double y)
{
    if (!(x < 10))
        throw std::range_error("index out of range");
    data[x] = y;
}

double get_something(int x)
{
    if (!(x < 10))
        throw std::range_error("index out of range");
    return data[x];
}

const double& get_something_rcref(int x)
{
    return data[x];
}

double& get_something_rref(int x)
{
    return data[x];
}

void get_something_ref(int x, double& y)
{
    y = get_something(x);
}

void get_something_ptr(int x, double* y)
{
    *y = get_something(x);
}

//---------------------------------------------------------------------------//
void print_array(const double* data, int count)
{
    cout << "{";
    const char* sep = "";
    for (const double* end_data = data + count; data != end_data; ++data)
    {
        cout << sep << *data;
        sep = ", ";
    }
    cout << "}\n";
}

//---------------------------------------------------------------------------//
// end of bare_function/bare.cc
//---------------------------------------------------------------------------//
