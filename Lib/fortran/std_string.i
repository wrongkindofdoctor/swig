//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_string.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 13:07:07 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <cstring.i>

%fragment("<string>");

//---------------------------------------------------------------------------//
// FRAGMENTS
//---------------------------------------------------------------------------//
/* When returning a std::string by value, store it in this temporary memory
 * space so that it's still allocated when the Fortran wrapper code converts it.
 */
%fragment("SWIG_store_string", "header", fragment="SwigArrayWrapper", fragment="<string>") %{
  SWIGINTERN SwigArrayWrapper SWIG_store_string(const std::string &str) {
    static std::string *temp = NULL;
    SwigArrayWrapper result;
    if (str.empty()) {
      // Result is empty
      result.data = NULL;
      result.size = 0;
    } else {
      if (!temp) {
        // Allocate a new temporary string
        temp = new std::string(str);
      } else {
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
// TYPEMAPS
//---------------------------------------------------------------------------//
// Optional string typemaps for native fortran conversion.
//
// Use:
//     %apply const std::string& NATIVE { const std::string& key };
//---------------------------------------------------------------------------//

// Fortran side treats like regular strings
%apply const char *NATIVE{ const std::string & NATIVE };

// C input translation typemaps: $1 is std::string*, $input is SwigArrayWrapper
%typemap(in) const std::string &NATIVE(std::string tempstr) %{
  tempstr = std::string(static_cast<const char *>($input->data), $input->size);
  $1 = &tempstr;
%}

// C output translation typemaps: $1 is string*, $input is SwigArrayWrapper
%typemap(out) const std::string &NATIVE %{
  $result.data = ($1->empty() ? NULL : &(*$1->begin()));
  $result.size = $1->size();
%}
// RETURN BY VALUE
%apply const std::string &NATIVE{ std::string NATIVE };

// Copy the string to a temporary buffer
%typemap(out, fragment = "SWIG_store_string") std::string NATIVE %{
  $result = SWIG_store_string($1);
%}

//---------------------------------------------------------------------------//
// DEFINITIONS
//---------------------------------------------------------------------------//
namespace std {
class string {
public:
  typedef std::size_t size_type;
  typedef char value_type;
  //typedef const char& const_reference;
  typedef const char *const_pointer;
  typedef char *pointer;

public:
  // >>> Construct and assign

  string();
  void resize(size_type count);
  void clear();

  // >>> ACCESS

  size_type size() const;
  size_type length() const;

  %extend {
    %apply const std::string &NATIVE{ const std::string & str };
    // Access as a newly allocated fortran string
    const std::string &str() { return *$self; }
  }
};
}

//---------------------------------------------------------------------------//
// end of fortran/std_string.i
//---------------------------------------------------------------------------//
