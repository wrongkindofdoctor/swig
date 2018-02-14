//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <typemaps.i>
%include <cstring.swg>
%fragment("<string>");

//---------------------------------------------------------------------------//
// When returning a std::string by value, store it in this temporary memory
// space so that it's still allocated when the Fortran wrapper code converts it.
%fragment("SWIG_store_string", "header", fragment="SwigArrayWrapper",
          fragment="<string>") %{

SWIGINTERN SwigArrayWrapper SWIG_store_string(const std::string& str)
{
    static std::string* temp = NULL;
    SwigArrayWrapper result;
    if (str.empty())
    {
        // Result is empty
        result.data = NULL;
        result.size = 0;
    }
    else
    {
        if (!temp)
        {
            // Allocate a new temporary string
            temp = new std::string(str);
        }
        else
        {
            // Assign the string
            *temp = str;
        }
        result.data = &(*(temp->begin()));
        result.size = temp->size();
    }
    return result;
}
%}

//---------------------------------------------------------------------------//
// Optional string typemaps for native fortran conversion.
//
// Use:
//     %apply const std::string& NATIVE { const std::string& key };
//---------------------------------------------------------------------------//

// C wrapper type: pointer to templated array wrapper
%typemap(ctype, noblock=1, out="SwigArrayWrapper",
       null="SwigArrayWrapper_uninitialized()",
       fragment="SwigArrayWrapper") std::string NATIVE
{SwigArrayWrapper*}

// C input translation typemaps: $1 is std::string*, $input is SwigArrayWrapper
%typemap(in) std::string NATIVE (std::string tempstr)
%{tempstr = std::string(static_cast<const char*>($input->data), $input->size);
$1 = &tempstr;
%}

// C output translation typemaps: $1 is string*, $input is SwigArrayWrapper
%typemap(out, fragment="SWIG_store_string") std::string NATIVE
%{
  $result = SWIG_store_string($1);
%}

%typemap(imtype, import="SwigArrayWrapper") std::string NATIVE
 "type(SwigArrayWrapper)"

// Fortran proxy code: return allocatable string
%typemap(ftype, out="character(kind=C_CHAR, len=:), allocatable")
    std::string NATIVE
  "character(kind=C_CHAR, len=*), target"

%typemap(findecl) std::string NATIVE
%{
  character(kind=C_CHAR), dimension(:), allocatable, target :: $1_chars
%}
%typemap(fin, fragment="SWIG_string_to_chararray_f", noblock=1) std::string NATIVE
%{
  call swig_string_to_chararray($input, $1_chars, $1)
%}

// Fortran proxy translation code: convert from char array to Fortran string
%typemap(fout, fragment="SWIG_chararray_to_string_f") std::string NATIVE
%{
  call SWIG_chararray_to_string($1, $result)
%}

// RETURN BY CONST REFERENCE

%apply std::string NATIVE { const std::string& NATIVE };

// C output translation typemaps: $1 is string*, $input is SwigArrayWrapper
%typemap(out) const std::string& NATIVE
%{$result.data = ($1->empty() ? NULL : &(*$1->begin()));
  $result.size = $1->size();
  %}

%apply const std::string& NATIVE { const std::string* NATIVE };

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
