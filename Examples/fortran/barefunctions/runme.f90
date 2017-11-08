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
    real(kind=8), dimension(9) :: arr
    real(kind=8), allocatable, dimension(:) :: alloc
    real(kind=8), dimension(3,3) :: mat
    integer :: i, j
    real(kind=8), pointer :: rptr

    call set_something(2, 200.0d0)
    call set_something(1, 10.0d0)
    call set_something(0, 1.0d0)
    write(0, *) "Got ", get_something(0)
    write(0, *) "Got ", get_something(1)

    rptr => get_something_rref(2)
    rptr = 512.0d0

    call get_something_ptr(2, temp)
    write(0, *) "Got ", temp
    call get_something_ref(1, temp)
    write(0, *) "Got ", temp

    do i = 1,size(arr)
        arr(i) = real(i) + 0.5
    end do

    write(0, *) "Printing array..."
    call print_array(arr)
    write(0, *) "... printed"

    ! Empty array
    write(0, *) "Printing empty..."
    allocate(alloc(0))
    call print_array(alloc)

    ! Matrix slice
    do i = 1,3
        do j = 1,3
            mat(i,j) = (i-1) + 3*(j-1)
        enddo
    enddo
    !write(0,*) mat

    ! THIS PRINTS BAD DATA for columns since they're not contiguous
    ! (fortran is row-major)
    write(0,*) "---- Column access is OK ----"
    
    do i = 1,3
        write(0, *) "Printing 2D array col ", i, " slice..."
        call print_array(mat(:,i))
    enddo

    ! THIS PRINTS BAD DATA for columns since they're not contiguous
    ! (fortran is row-major)
    write(0,*) "---- Row access is NOT ok ----"
    
    do i = 1,3
        write(0, *) "Printing 2D array row ", i, " slice..."
        call print_array(mat(i,:))
    enddo

    deallocate(alloc)
    allocate(alloc(3))

    write(0,*) "---- Correct row access ----"
    
    ! Instead, do this since allocatable data is contiguous:
    do i = 1,3
        ! This doesn't work???
        write(0, *) "Printing 2D array row ", i, " slice..."
        alloc(:) = mat(i,:)
        call print_array(alloc)
    enddo
    
end program

!-----------------------------------------------------------------------------!
! end of swig-fortran/test.f90
!-----------------------------------------------------------------------------!
