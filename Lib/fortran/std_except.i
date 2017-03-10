//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_except.i
 * \author Seth R Johnson
 * \date   Mon Mar 06 09:53:09 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%fragment("FortranException", "header") %{
#include <string>
#include <stdexcept>
#include <algorithm>

namespace swig
{
int fortran_exception_code = 0;
std::string fortran_exception_str;

SWIGINTERN void fortran_delayed_exception_check()
{
    if (fortran_exception_code != 0)
        throw std::runtime_error("An unhandled exception occurred: "
                                 + fortran_exception_str);
}

SWIGINTERN void fortran_store_exception(int code, const char *msg)
{
    fortran_exception_code = code;
    fortran_exception_str = msg;
}
}
%}

%include <std/std_except.i>

//---------------------------------------------------------------------------//
// end of fortran/std_except.i
//---------------------------------------------------------------------------//
