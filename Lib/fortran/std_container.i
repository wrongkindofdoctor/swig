//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   fortran/std_container.i
 * \author Seth R Johnson
 * \date   Sun Jan 28 11:38:34 2018
 * \note   Copyright (c) 2018 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//
// Native typemaps for contiguous arrays: translate directly to and from Fortran
// arrays. Returns an allocatable array copy of a std::vector reference.
//
// To avoid wrapping std::vector but still instantiate the typemaps that
// allow native wrapping, use %template() std::vector<double>
//---------------------------------------------------------------------------//

%include <view.i>

//---------------------------------------------------------------------------//
/*!
 * \def %std_native_container
 *
 * Native typemaps for contiguous arrays: translate directly to and from Fortran
 * arrays.
 *
 * - The inputs are contiguous array views
 * - The outputs are allocatable arrays
 */
%define %std_native_container(ARRTYPE...)

#define VTYPE ARRTYPE::value_type
FORT_ARRAYPTR_TYPEMAP(VTYPE, const ARRTYPE& NATIVE)

// C input translation typemaps: $1 is SWIGPAIR__, $input is SwigArrayWrapper
%typemap(in, noblock=1) const ARRTYPE& NATIVE (ARRTYPE temparr, VTYPE* tempbegin)
  {tempbegin = static_cast<VTYPE*>($input->data);
   temparr.assign(tempbegin, tempbegin + $input->size);
   $1 = &temparr;
   }

// C output translation typemaps: $1 is vector<VTYPE>*, $input is SwigArrayWrapper
%typemap(out) const ARRTYPE& NATIVE
%{$result.data = ($1->empty() ? NULL : &(*$1->begin()));
  $result.size = $1->size();
  %}

%typemap(ftype, out={$typemap(imtype, VTYPE), dimension(:), allocatable},
noblock=1) const ARRTYPE& NATIVE
  {$typemap(imtype, VTYPE), dimension(:), target, intent(in)}

// Fortran proxy translation code: convert from imtype $1 to ftype $result
%typemap(foutdecl, noblock=1) const ARRTYPE& NATIVE
{$typemap(imtype, VTYPE), pointer :: $1_view(:)}

%typemap(fout, noblock=1) const ARRTYPE& NATIVE
{call c_f_pointer($1%data, $1_view, [$1%size])
 allocate($typemap(imtype, VTYPE) :: $result(size($1_view)))
 $result = $1_view}

#undef VTYPE

%enddef


//---------------------------------------------------------------------------//
// end of fortran/std_container.i
//---------------------------------------------------------------------------//
