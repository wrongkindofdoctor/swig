program ret_by_value_runme

  use ret_by_value
  use iso_fortran_env

  type(test) :: test_val
  logical :: okay

  okay = .true.

  test_val = get_test()

  if(test_val%myInt /= 100) then
    write(*,*)"Wrong value for %myInt",100
    okay = .false.
  endif


  if(.not.okay) then
    stop 1
  endif


end program
