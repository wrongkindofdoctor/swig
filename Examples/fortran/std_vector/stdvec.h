//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   std_vector/stdvec.h
 * \author Seth R Johnson
 * \date   Mon Dec 05 09:06:12 2016
 * \brief  stdvec class declaration.
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef std_vector_stdvec_hh
#define std_vector_stdvec_hh

#include <cstddef>
#include <vector>

//---------------------------------------------------------------------------//
template<class T>
std::pair<T*, size_t> make_view(std::vector<T>& v)
{
    if (v.empty())
        return {};
    return {v.data(), v.size()};
}
//---------------------------------------------------------------------------//
template<class T>
std::pair<const T*, size_t> make_const_view(const std::vector<T>& v)
{
    if (v.empty())
        return {};
    return {v.data(), v.size()};
}

//---------------------------------------------------------------------------//

template<class T>
void print_vec(const std::vector<T>& v);

//---------------------------------------------------------------------------//

template<class T>
void print_view(std::pair<const T*, size_t> view);

//---------------------------------------------------------------------------//
template<class T>
const std::vector<T>& get_vec(const std::vector<T>& inp)
{
    return inp;
}

//---------------------------------------------------------------------------//
#endif // std_vector_stdvec_hh

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.h
//---------------------------------------------------------------------------//
