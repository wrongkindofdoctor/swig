!-----------------------------------------------------------------------------!
! \file   exceptions/test.f90
! \author Seth R Johnson
! \date   Mon Mar 06 10:04:28 2017
! \brief  test module
! \note   Copyright (c) 2017 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    use ISO_FORTRAN_ENV
    use except
    implicit none
    integer :: val, ierr
    character(len=128) :: errmsg

    call alpha(-4)
    ! ierr = get_swig_ierr()
    ! if (ierr /= 0) then
    !     call get_swig_serr(errmsg)
    !     write(*,*) "Got error: ", errmsg
    !     write(*,*) "Aborting..."
    !     stop 0
    ! endif

    val = bravo()

end program

!-----------------------------------------------------------------------------!
! end of exceptions/test.f90
!-----------------------------------------------------------------------------!
