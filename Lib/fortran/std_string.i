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

    // >>> Construct and assign

    string();
    void resize(size_type count);
    void clear();

    // >>> ACCESS

    size_type size() const;
    size_type length() const;

%extend {

    // C indexing used here!
    void set(size_type pos, value_type v)
    {
        // TODO: check range
        (*$self)[pos] = v;
    }

    // C indexing used here!
    value_type get(size_type pos)
    {
        // TODO: check range
        return (*$self)[pos];
    }

    void assign_from(std::pair<const char*, size_t> view)
    {
        $self->assign(view.first, view.first + view.second);
    }

    std::pair<char*, size_t> view()
    {
        char* begin_ptr;
        size_t size = $self->size();
        if (size == 0)
        {
            begin_ptr = NULL;
        }
        else
        {
            begin_ptr = &(*$self->begin());
        }
        return std::make_pair(begin_ptr, size);
    }

} // end %extend

};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
