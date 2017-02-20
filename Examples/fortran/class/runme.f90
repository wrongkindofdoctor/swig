program class_runme
  use example

  implicit none

  type(Circle) :: c
  type(Square) :: s

  ! Create objects
  write(*,*) "Creating some objects"
  call c%create(10.0_8)
  call s%create(10.0_8)

  ! Access static member
  write(*,'(a,i2,a)')"A total of", c%get_nshapes(), " shapes were created"

  ! Member data access. TODO: This is done now using the move method, but since
  ! the members are public, accessors should be generated automatically
  call c%move(20.0_8, 30.0_8)
  call s%move(-10.0_8, 5.0_8)

  ! Need accessors for public members to be able to do this
  !write(*,*)"Here is their current position:"
  !write(*,*)"    Circle = (", c% ",", " )"

  ! Call some methods
  write(*,*)"Here are some properties of the shapes:"
  write(*,*)"    Circle:"
  write(*,*)"        area      = ",c%area()
  write(*,*)"        perimeter = ",c%perimeter()
  write(*,*)"    Square:"
  write(*,*)"        area      = ",s%area()
  write(*,*)"        perimeter = ",s%perimeter()

  ! Clean up
  call c%release()
  call s%release()

  ! Check n shapes
  write(*,*)c%get_nshapes(), "shapes remain"
  write(*,*)"Goodbye"




end program
