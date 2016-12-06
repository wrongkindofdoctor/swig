!-----------------------------------------------------------------------------!
! \file   algorithms/test.f90
! \author Seth R Johnson
! \date   Tue Dec 06 11:30:02 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    use ISO_FORTRAN_ENV
    use, intrinsic :: ISO_C_BINDING
    use algorithm, only : reverse, &
                          find_sorted => find_sorted_integer
    implicit none
    integer :: i
    integer(C_INT), dimension(6) :: test_data = (/ -1, 1, 3, 3, 5, 7 /)
    real(C_FLOAT), dimension(4)  :: test_real = (/ 0.1, 1.9, -2.0, 4.0 /)
    character(len=*), parameter :: list_fmt = "(*(i4,"",""))"

    write (0,list_fmt) test_data
    call reverse(test_data)
    write (0,list_fmt) test_data

    write (0,*) test_real
    call sort(test_real)
    call reverse(test_real)
    write (0,*) test_real

    ! Restore it
    call reverse(test_data)

    do i = -2,8
        write(0, "(i4,""->"",i4)") i, find_sorted(test_data, i)
    enddo

end program

!-----------------------------------------------------------------------------!
! end of algorithms/test.f90
!-----------------------------------------------------------------------------!
