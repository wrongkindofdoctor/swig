//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   std_string/stdstr.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 18:32:13 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
%module stdstr

%{
#include "stdstr.hh"
%}

// Instantiate views of C strings
%include <typemaps.i>
%fortran_string_view(char)

// Add headers needed for "copy_to" function
%{
#include <stdexcept>
#include <algorithm>
#include <sstream>
%}

// Extend string to support views
%extend std::string {
    // Copy from a fortran string
    void assign_from(std::pair<const char*, size_t> view)
    {
        $self->assign(view.first, view.first + view.second);
    }

    // Get an array-like view to the string
    std::pair<const char*, std::size_t> view()
    {
        if ($self->empty())
            return {nullptr, 0};
        return {$self->data(), $self->size()};
    }

    // Fill a fortran string, add trailing whitespace
    void copy_to(std::pair<char*, size_t> view)
    {
        if (view.second < $self->size())
        {
            std::ostringstream os;
            os << "String size too small: " << view.second
                << " < " << $self->size();
            throw std::range_error(os.str());
        }

        char* s = view.first;
        s = std::copy($self->begin(), $self->end(), s);
        std::fill_n(s, view.second - $self->size(), ' ');
    }
} // end extend


%include <std_string.i>

// Use native fortran string conversion for one particular function
%apply std::string NATIVE { std::string get_reversed_native_string };
%apply const std::string& NATIVE { const std::string& input };

%include "stdstr.hh"

//---------------------------------------------------------------------------//
// end of std_string/stdstr.i
//---------------------------------------------------------------------------//
