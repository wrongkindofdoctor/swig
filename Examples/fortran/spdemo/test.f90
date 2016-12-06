!-----------------------------------------------------------------------------!
! \file   spdemo/test.f90
! \author Seth R Johnson
! \date   Tue Dec 06 15:37:51 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

subroutine test_class()
    use ISO_FORTRAN_ENV
    use spdemo, only : Foo, printfoo => print_crsp
    implicit none
    type(Foo) :: f

    write(0, *) "Constructing..."
    call f%create()
    write(0, *) "Setting..."
    call f%set(123.0d0)
    write(0, *) "Current value ", f%get()
    call printfoo(f)
    call f%release()
    !call printfoo(f)
end subroutine

program main
    implicit none

    call test_class()
end program

!-----------------------------------------------------------------------------!
! end of spdemo/test.f90
!-----------------------------------------------------------------------------!
