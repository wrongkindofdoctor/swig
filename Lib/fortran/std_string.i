//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <typemaps.i>
%fragment("<string>");

//---------------------------------------------------------------------------//
// Standard string class
//---------------------------------------------------------------------------//
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

    //

%extend {
    // XXX: overload for fortran string assignment
#if 0
    // Assignment from fortran string
    void operator=(const std::string& inp)
    {
        *$self = inp;
    }
#endif

    %apply const std::string& NATIVE { const std::string& str};

    // Access as a newly allocated fortran string
    const std::string& str()
    {
        return *$self;
    }
} // end %extend

};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
