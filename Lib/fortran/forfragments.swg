//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/fragments.swg
 * \author Seth R Johnson
 * \date   Sun Apr 30 10:11:28 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%fragment("<string>", "header") %{
#include <string>
%}
%fragment("<algorithm>", "header") %{
#include <algorithm>
%}
%fragment("<stdexcept>", "header") %{
#include <stdexcept>
%}
%fragment("<sstream>", "header") %{
#include <sstream>
%}

// Fill a Fortran string from a std::string; with whitespace after
%fragment("ArraySizeCheck", "header", 
          fragment="<stdexcept>", fragment="<sstream>") %{
namespace swig
{
void array_size_check(size_t src, size_t dst)
{
    if (dst < src)
    {
        std::ostringstream os;
        os << "Array size mismatch: " << src << " != " << dst;
        throw std::range_error(os.str());
    }
}
}

%}

// Fill a Fortran string from a std::string; with whitespace after
%fragment("StringCopyout", "header", fragment="<string>",
          fragment="<stdexcept>", fragment="<sstream>") %{
namespace swig
{
void string_size_check(size_t src, size_t dst)
{
    if (dst < src)
    {
        std::ostringstream os;
        os << "String size too small: " << dst << " < " << src;
        throw std::range_error(os.str());
    }
}

void string_copyout(const std::string& str, char* s, size_t count)
{
    string_size_check(str.size(), count);

    s = std::copy(str.begin(), str.end(), s);
    std::fill_n(s, count - str.size(), ' ');
}
}

%}

//---------------------------------------------------------------------------//
// end of fortran/fragments.swg
//---------------------------------------------------------------------------//
