//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include "std_common.i"

%fragment("<algorithm>");
%fragment("<stdexcept>");
%fragment("<string>");
%fragment("StringCopyout");

%include <typemaps.i>

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
        (pointer s, size_type count) };
    %apply (const char* STRING, int SIZE) {
        (const_pointer s, size_type count) };

    // >>> Construct and assign

    string();
    string(const_pointer s, size_type count);
    void resize(size_type count);
    void clear();

    // >>> ACCESS

    size_type size() const;
    size_type length() const;

%extend {
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

    void assign_from(const_pointer s, size_type count)
    {
        $self->assign(s, s + count);
    }

    // Copy the string to the given Fortran string, filling the tail with
    // spaces so that Fortran 'trim' will work.
    void copy_to(pointer s, size_type count)
    {
        swig::string_copyout(*$self, s, count);
    }

} // end %extend

};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
