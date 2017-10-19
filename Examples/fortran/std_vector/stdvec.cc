//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   std_vector/stdvec.cc
 * \author Seth R Johnson
 * \date   Mon Dec 05 09:06:12 2016
 * \brief  stdvec class definitions.
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#include "stdvec.hh"

#include <iostream>
using std::cout;
using std::endl;

//---------------------------------------------------------------------------//
// FREE FUNCTIONS
//---------------------------------------------------------------------------//

template<class T>
void print_vec(const std::vector<T>& v)
{
    print_view<const T>(make_const_view(v));
}

template<class T>
void print_view(VectorView<const T> vec)
{
    cout << "{";
    const char* sep = "";
    for (const T& v : vec)
    {
        cout << sep << v;
        sep = ", ";
    }
    cout << "}" << endl;
}

//---------------------------------------------------------------------------//
// EXPLICIT INSTANTIATION
//---------------------------------------------------------------------------//

template void print_vec(const std::vector<double>&);
template void print_vec(const std::vector<int>&);
template void print_view(VectorView<const double>);
template void print_view(VectorView<const int>);

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.cc
//---------------------------------------------------------------------------//
