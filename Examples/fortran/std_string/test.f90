!-----------------------------------------------------------------------------!
! \file   std_string/test.f90
! \author Seth R Johnson
! \date   Mon Dec 05 18:31:18 2016
! \brief  test module
! \note   Copyright (c) 2016 Oak Ridge National Laboratory, UT-Battelle, LLC.
!-----------------------------------------------------------------------------!

program main
    use ISO_FORTRAN_ENV
    use, intrinsic :: ISO_C_BINDING
    use stdstr, only : print_str, halve_str, string
    implicit none
    character(len=*), parameter :: paramstr = "short string   "
    character(len=:), allocatable :: varlen
    character(kind=C_CHAR), dimension(:), pointer :: ptrstr
    character(len=16) :: fixedlen
    integer :: i
    type(string) :: s

    write(0, *) "Constructing..."
    call s%create()
    write(0, *) "Size:", s%size()

    call s%assign_from(trim(paramstr))
    write(0, *) "Assigned from trimmed string:"
    call print_str(s)

    fixedlen = "fixed"
    call s%assign_from(fixedlen)
    write(0, *) "Assigned from fixed-length string:"
    call print_str(s)

    ! Cut it in half and read it back out to varlen
    write(0, *) "Halving..."
    call halve_str(s)

    ptrstr => s%view()
    write(0, *) "String view size:", size(ptrstr)

    ! Get a view of the string as an array of single chars
    call halve_str(s)
    ptrstr => s%view()

    ! NOTE: putting the size call inside the allocate call crashes fortran.
    write(0, *) "Allocating and copying to varlen"
    i = size(ptrstr)
    allocate(character(len=i) :: varlen)
    do i = 1,len(varlen)
        varlen(i:i) = ptrstr(i)
    enddo

    write(0, *) "Quarter-length string: '"//varlen//"'"

    ! Copy string to fix-length array (alternate way of extracting)
    fixedlen = "XXXXXXXXXXXXXXXX"
    call s%copy_to(fixedlen)
    write(0, *) "Fixed-length string: '"//fixedlen//"'"

    write(0, *) "Destroying..."
    call s%release()
    deallocate(varlen)

end program


!-----------------------------------------------------------------------------!
! end of std_string/test.f90
!-----------------------------------------------------------------------------!
