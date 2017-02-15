!-----------------------------------------------------------------------------!
! \file   swig-fortran/test.f90
! \author Seth R Johnson
! \date   Wed Nov 30 18:15:24 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    use ISO_FORTRAN_ENV
    use bare
    implicit none
    real(kind=8) :: temp
    real(kind=8), dimension(1) :: temparr
    real(kind=8), dimension(9) :: arr
    integer :: i

    call set_something(2, 200.0d0)
    call set_something(1, 10.0d0)
    call set_something(0, 1.0d0)
    write(0, *) "Got ", get_something(0)
    write(0, *) "Got ", get_something(1)

    call get_something_ptr(2, temparr)
    write(0, *) "Got ", temparr
    call get_something_ref(1, temp)
    write(0, *) "Got ", temp


    do i = 1,size(arr)
        arr(i) = real(i) + 0.5
    end do

    write(0, *) "Printing array..."
    call print_array(arr)
    write(0, *) "... printed"
    
end program

!-----------------------------------------------------------------------------!
! end of swig-fortran/test.f90
!-----------------------------------------------------------------------------!
