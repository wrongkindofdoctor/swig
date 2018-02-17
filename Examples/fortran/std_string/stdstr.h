//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   std_string/stdstr.h
 * \author Seth R Johnson
 * \date   Mon Dec 05 18:32:13 2016
 * \brief  stdstr class declaration.
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef std_string_stdstr_hh
#define std_string_stdstr_hh

#include <string>

void print_str(const std::string &s);

void halve_str(std::string &s);

std::string get_reversed_native_string(const std::string &input);

#endif

//---------------------------------------------------------------------------//
// end of std_string/stdstr.h
//---------------------------------------------------------------------------//
