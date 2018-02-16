//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_array.i
 * \author Seth R Johnson
 * \date   Wed May 10 10:28:03 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%{
#include <array>
%}

#warning "std::array support is not yet implemented"

namespace std {
template<class T, size_t N>
class array {
public:
};
}

//---------------------------------------------------------------------------//
// end of fortran/std_array.i
//---------------------------------------------------------------------------//
