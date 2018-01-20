//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_pair.i
 * \author Seth R Johnson
 * \date   Wed May 10 10:28:03 2017
 * \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%include <std_common.i>

%fragment("<utility>");

namespace std
{

template<class T, class U> struct pair
{
    pair();
    pair(T first, U second);
    pair(const pair& p);
    template <class U1, class U2> pair(const pair<U1, U2> &p);

    T first;
    U second;
};

}

//---------------------------------------------------------------------------//
// end of fortran/std_pair.i
//---------------------------------------------------------------------------//
