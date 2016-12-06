//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%{
#include <string>
#include <algorithm>
#include <stdexcept>
%}

namespace std
{
class string
{
  public:
    typedef std::size_t size_type;
    typedef char        value_type;
    //typedef const char& const_reference;
    typedef const char* const_pointer;
    typedef char*       pointer;

  public:

    %apply int { (size_type count) };
    %apply (char* STRING, int SIZE) {
        (const_pointer s, size_type count),
        (pointer s, size_type count) };

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
        if ($self->size() > count)
            throw std::range_error("copy_to string is too small");

        s = std::copy($self->begin(), $self->end(), s);
        std::fill_n(s, count - $self->size(), ' ');
    }
} // end %extend

};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
