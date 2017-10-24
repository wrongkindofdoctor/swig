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

%include <std_pair.i>
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

    // Instantiate typemaps for views
    %fort_view_typemap(_Tp);

    // Extend for Fortran
%extend {
    // C indexing used here!
    void set(size_type index, const_reference v)
    {
        // TODO: check range
        (*$self)[index] = v;
    }

    // C indexing used here!
    value_type get(size_type index)
    {
        return (*$self)[index];
    }

    std::pair<_Tp*, size_t> view()
    {
        _Tp* begin_ptr;
        size_t size = $self->size();
        if (size == 0)
        {
            begin_ptr = NULL;
        }
        else
        {
            begin_ptr = &((*$self)[0]);
        }
        return std::make_pair(begin_ptr, size);
    }
} // end extend

};

// Specialize on bool
template<class _Alloc >
class vector<bool,_Alloc >
{
    /* NOT IMPLEMENTED */
};

} // end namespace std

//---------------------------------------------------------------------------//
// end of fortran/std_vector.i
//---------------------------------------------------------------------------//
