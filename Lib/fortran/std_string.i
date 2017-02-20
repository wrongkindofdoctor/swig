//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef SWIG_FORTRAN_STD_SIZETYPE
#define SWIG_FORTRAN_STD_SIZETYPE int
#endif

%{
#include <string>
#include <algorithm>
#include <stdexcept>
%}


%fragment("StdStringCopyout", "header") {

// Fill a Fortran string from a std::string; with whitespace after
void std_string_copyout(const std::string& str, char* s, size_t count)
{
    if (str.size() > count)
        throw std::range_error("string size too small");

    s = std::copy(str.begin(), str.end(), s);
    std::fill_n(s, count - str.size(), ' ');
}

}

namespace std
{
class string
{
  public:
    typedef SWIG_FORTRAN_STD_SIZETYPE size_type;
    typedef char        value_type;
    //typedef const char& const_reference;
    typedef const char* const_pointer;
    typedef char*       pointer;

  public:

    %apply int { (size_type count) };
    %apply (char* STRING, int SIZE) {
        (const_pointer s, size_type count),
        (pointer s, size_type count) };

    %fragment("StdStringCopyout");

    // >>> Construct and assign

    string();
    string(const_pointer s, size_type count);
    void resize(size_type count);
    void clear();

    // >>> ACCESS

    size_type size() const;
    size_type length() const;

%extend {
#if 0
    void set(size_type pos, value_type v)
    {
        // TODO: check range
        (*$self)[pos] = v;
    }

    value_type get(size_type pos)
    {
        // TODO: check range
        return (*$self)[pos];
    }
#endif

    void assign_from(const_pointer s, size_type count)
    {
        $self->assign(s, s + count);
    }

    // Copy the string to the given Fortran string, filling the tail with
    // spaces so that Fortran 'trim' will work.
    void copy_to(pointer s, size_type count)
    {
        std_string_copyout(*$self, s, count);
    }

} // end %extend

};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
