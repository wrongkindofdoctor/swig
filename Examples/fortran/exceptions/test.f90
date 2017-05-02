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
    integer :: val = 123

    write(*,*) "Making bad subroutine call"
    call alpha(-4)

    if (ierr /= 0) then
        write(*,*) "Got error ", ierr, ": ", trim(serr)
        ! stop 0
        write(*,*) "Recovering..."
        ! Clear error flag
        ierr = 0
    endif

    write(*,*) "Making bad function call"
    val = bravo()
    write(*,*) "Result of bad function call:", val

!    write(*,*) "Making another bad function call will terminate the app"
!    val = bravo()

    ! Clear the error
    ierr = 0
    call alpha(3)
    val = bravo()
    write(*,*) "Result of good function call:", val


end program

!-----------------------------------------------------------------------------!
! end of exceptions/test.f90
!-----------------------------------------------------------------------------!
