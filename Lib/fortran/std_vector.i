//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_vector.i
 * \author Seth R Johnson
 * \date   Mon Dec  5 09:18:06 2016
 * \brief  Fortran std::vector code
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%{
#include <vector>
%}

%include "std_common.i"

// Force inclusion of algorithm and stdexcept
%fragment("<algorithm>");
%fragment("ArraySizeCheck");

%include <typemaps.i>

namespace std
{

template<class _Tp, class _Alloc = std::allocator< _Tp > >
class vector
{
  public:
    // NOTE: using int rather than size_t for fortran compatibility
    typedef SWIG_FORTRAN_STD_SIZETYPE  size_type;
    typedef _Tp               value_type;
    typedef value_type*       pointer;
    typedef const value_type* const_pointer;
    typedef _Tp&              reference;
    typedef const _Tp&        const_reference;
    typedef _Alloc            allocator_type;

  public:

    // Constructors
    vector();
    vector(size_type count);
    vector(size_type count, const value_type& v);

    // Accessors
    size_type size() const;
    size_type capacity() const;
    bool empty() const;
    void clear();

    // Modify
    void reserve(size_type count);
    void resize(size_type count);
    void resize(size_type count, const value_type& v);
    void push_back(const value_type& v);

    const_reference front() const;
    const_reference back() const;

    // Extend for Fortran: c indexing!
%extend {
    void set(size_type index, const_reference v)
    {
        // TODO: check range
        (*$self)[index] = v;
    }

    value_type get(size_type index)
    {
        return (*$self)[index];
    }

    %apply (SWIGTYPE* ARRAY, SWIG_FORTRAN_STD_SIZETYPE SIZE)
    { (pointer       arr, size_type arrsize),
      (const_pointer arr, size_type arrsize) };

    void assign_from(const_pointer arr, size_type arrsize)
    {
        $self->assign(arr, arr + arrsize);
    }

    // Copy the C++ data to the given Fortran arr. Sizes must match.
    void copy_to(pointer arr, size_type arrsize)
    {
        swig::array_size_check($self->size(), arrsize);
        std::copy($self->begin(), $self->end(), arr);
    }

} // end extend
};

} // end namespace std

//---------------------------------------------------------------------------//
// end of fortran/std_vector.i
//---------------------------------------------------------------------------//
