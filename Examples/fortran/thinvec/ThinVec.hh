//---------------------------------*-C++-*-----------------------------------//
/*!
 * \file   thinvec/ThinVec.hh
 * \author Seth R Johnson
 * \date   Mon Jan 19 08:59:42 2015
 * \brief  thinvec class declaration.
 * \note   Copyright (c) 2015 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

#ifndef thinvec_ThinVec_hh
#define thinvec_ThinVec_hh

#include <vector>

template<class T>
class ThinVec
{
  private:
    std::vector<T> d_data;

  public:
    typedef int size_type;
    typedef T            value_type;
    typedef T*           pointer;
    typedef const T*     const_pointer;
    typedef std::pair<pointer, std::size_t> view_type;
    typedef std::pair<const_pointer, std::size_t> const_view_type;

  public:
    // Constructors
    ThinVec()
        : d_data()
    { /* * */ }

    ThinVec(size_type count, value_type fillval = 0)
        : d_data(count, fillval)
    { /* * */ }

    // Accessors
    bool empty() const
    { return d_data.empty(); }

    size_type size() const
    { return d_data.size(); }

    const value_type& get(size_type index) const
    { return d_data.at(index); }

    void set(size_type index, const value_type& val)
    { d_data.at(index) = val; }

    void resize(size_type newsize, value_type fillval = T())
    { d_data.resize(newsize, fillval); }

    void assign(const_view_type arr);

    view_type view();

    const std::vector<T>& data() const { return d_data; }
};

void print_vec(const ThinVec<double>& v);

#endif // thinvec_ThinVec_hh

//---------------------------------------------------------------------------//
// end of swig-dev/thinvec/ThinVec.hh
//---------------------------------------------------------------------------//
