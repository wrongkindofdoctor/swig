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

namespace std
{

template<class _Tp, class _Alloc = std::allocator< _Tp > >
class vector
{
  public:
    typedef std::size_t       size_type;
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
        // TODO: check range
        return (*$self)[index];
    }
} // end extend

#define SWIGVEC__ const std::vector<_Tp>& NATIVE
#define SWIGFTYPE__ "$typemap(imtype, " #_Tp ")"
// C wrapper type: pointer to templated array wrapper
%typemap(ctype, noblock=1, out="SwigfArrayWrapper",
       null="SwigfArrayWrapper_uninitialized()",
       fragment="SwigfArrayWrapper_wrap") SWIGVEC__
{SwigfArrayWrapper*}

%typemap(imtype, import="SwigfArrayWrapper") SWIGVEC__
  "type(SwigfArrayWrapper)"

// Fortran proxy code: return allocatable vector<CTYPE>
%typemap(ftype, out={$typemap(imtype, _Tp ), dimension(:), allocatable},
noblock=1) SWIGVEC__
  {$typemap(imtype,  _Tp ), dimension(:), target, intent(in)}

// C output translation typemaps: $1 is vector<CTYPE>*, $input is SwigfArrayWrapper
%typemap(out) SWIGVEC__
%{$result.data = ($1->empty() ? NULL : &(*$1->begin()));
  $result.size = $1->size();
  %}

// Fortran proxy translation code: convert from ftype $input to imtype $1
%typemap(findecl, noblock=1) SWIGVEC__
  {$typemap(imtype, _Tp ), pointer :: $1_view}
%typemap(fin) SWIGPAIR__
%{$1_view => $input(1)
  $1%data = c_loc($1_view)
  $1%size = size($input)%}

// Fortran proxy translation code: convert from imtype $1 to ftype $result
%typemap(foutdecl, noblock=1) SWIGVEC__
    {$typemap(imtype, _Tp), pointer :: $1_view(:)}
%typemap(fout, noblock=1) SWIGVEC__
{ call c_f_pointer($1%data, $1_view, [$1%size])
  allocate($typemap(imtype, _Tp) :: $result(size($1_view)))
  $result = $1_view}

#undef SWIGVEC__
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
