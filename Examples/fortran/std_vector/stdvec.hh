//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   std_vector/stdvec.hh
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
class VectorView
{
  public:
    typedef int size_type;
    typedef T*  pointer_type;

  private:
    pointer_type d_begin;
    pointer_type d_end;

  public:
    VectorView() : d_begin(NULL), d_end(NULL)
    { /* * */ }

    VectorView(pointer_type begin, pointer_type end)
        : d_begin(begin)
        , d_end(end)
    { /* * */ }

    template<class U>
    VectorView(VectorView<U> other)
        : d_begin(other.d_begin)
        , d_end(other.d_end)
    { /* * */ }

    size_type size() const { return d_end - d_begin; }
    pointer_type data() const { return d_begin; }

#ifndef SWIG
    pointer_type begin() const { return d_begin; }
    pointer_type end() const { return d_end; }
#endif

    template<class U> friend class VectorView;
};

//---------------------------------------------------------------------------//
template<class T>
VectorView<const T> make_const_view(const std::vector<T>& v)
{
    if (v.empty())
        return {};
    return {v.data(), v.data() + v.size()};
}

//---------------------------------------------------------------------------//
template<class T>
VectorView<T> make_view(std::vector<T>& v)
{
    if (v.empty())
        return {};
    return {v.data(), v.data() + v.size()};
}

//---------------------------------------------------------------------------//

template<class T>
void print_vec(const std::vector<T>& v);

//---------------------------------------------------------------------------//
template<class T>
void print_view(VectorView<T> view)
{
    print_view(VectorView<const T>(view));
}

//---------------------------------------------------------------------------//
template<class T>
void print_view(VectorView<const T> view);

//---------------------------------------------------------------------------//
#endif // std_vector_stdvec_hh

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.hh
//---------------------------------------------------------------------------//
