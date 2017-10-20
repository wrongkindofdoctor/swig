//---------------------------------*-SWIG-*----------------------------------//
/*!
 * \file   std_vector/stdvec.i
 * \author Seth R Johnson
 * \date   Mon Dec 05 09:05:31 2016
 * \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
 */
//---------------------------------------------------------------------------//

%module stdvec

%{
#include "stdvec.hh"
%}

%include <std_vector.i>
%template(VecDbl) std::vector<double>;

%include "stdvec.hh"

%define TEMPLATE_VIEW(FCLASSNAME, TYPE, FTYPE)

%extend VectorView<TYPE>
{
%fortrancode %{
  function FCLASSNAME##_view(self) &
     result(fresult)
   use, intrinsic :: ISO_C_BINDING
   real(FTYPE), pointer :: fresult(:)
   real(FTYPE), pointer :: temp
   class(FCLASSNAME) :: self
   temp => self%data()
   call c_f_pointer(c_loc(temp), fresult, [self%size()])
  end function
%}
%fortranspec %{procedure :: view => FCLASSNAME##_view
%}
}

%template(FCLASSNAME) VectorView<TYPE>;
%enddef

TEMPLATE_VIEW(VecViewDbl, double, C_DOUBLE)
TEMPLATE_VIEW(const_VecViewDbl, const double, C_DOUBLE)

%template(make_viewdbl) make_view<double>;
%template(make_const_viewdbl) make_const_view<double>;
%template(print_viewdbl) print_view<double>;
%template(print_vecdbl)  print_vec<double>;

//---------------------------------------------------------------------------//
// end of std_vector/stdvec.i
//---------------------------------------------------------------------------//
