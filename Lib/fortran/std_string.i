//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include "std_common.i"

%fragment("<string>");

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
} // end %extend

};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
