//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   std_string/stdstr.cxx
 * \author Seth R Johnson
 * \date   Mon Dec 05 18:32:13 2016
 * \brief  stdstr class definitions.
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#include "stdstr.h"

#include <algorithm>
#include <iostream>
using std::cout;
using std::endl;

void print_str(const std::string& s)
{
    cout << "\"" << s << "\"" << endl;
}

void halve_str(std::string& s)
{
    s.erase(s.begin() + s.size() / 2, s.end());
}

std::string get_reversed_native_string(const std::string& input)
{
    std::string result(input);
    std::reverse(result.begin(), result.end());
    return result;
}

//---------------------------------------------------------------------------//
// end of std_string/stdstr.cxx
//---------------------------------------------------------------------------//
