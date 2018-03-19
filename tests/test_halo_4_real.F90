module data
  use params
  implicit none
  save

  real :: test_array(0:ksizex_l+1, 0:ksizey_l+1, 0:ksizet_l+1, 2)
  real :: test_array_2(0:ksizex_l+1, 0:ksizey_l+1, 0:ksizet_l+1, 2)
end module data

function pid(ip_x, ip_y, ip_t) result(id)
  use params
  implicit none
  integer, intent(in) :: ip_x, ip_y, ip_t
  integer :: id

  id = ip_x + ip_y * np_x + ip_t * np_x * np_y
end function pid

program test_halo_4_real
  use params
  use data
  use comms
  implicit none
  integer :: ix, iy, it, i5, i=0
  integer :: pid
#ifdef MPI
  integer, dimension(12) :: reqs, reqs2

  call init_MPI
#endif

  test_array(0,:,:,:) = cmplx(-1,-1)
  test_array(:,0,:,:) = cmplx(-2,-1)
  test_array(:,:,0,:) = cmplx(-3,-1)
  test_array(ksizex_l+1,:,:,:) = cmplx(-1,-2)
  test_array(:,ksizey_l+1,:,:) = cmplx(-2,-2)
  test_array(:,:,ksizet_l+1,:) = cmplx(-3,-2)

! Set up local arrays
  do i5=1,2
     do it=1,ksizet_l
        do iy=1,ksizey_l
           do ix=1,ksizex_l
              i = i + 1
              test_array(ix, iy, it, i5) = i
              test_array_2(ix, iy, it, i5) = pid(ip_x, ip_y, ip_t)
           end do
        end do
     end do
  end do

! Communicate
#ifdef MPI
  call start_halo_update_4_real(2, test_array, 0, reqs)
  call start_halo_update_4_real(2, test_array_2, 1, reqs2)
  call complete_halo_update(reqs)
  call complete_halo_update(reqs2)
#else
  call complete_halo_update_4_real(2, test_array)
#endif

! Check output
  if (test_array(1,1,1,1) .ne. test_array(ksizex_l+1,1,1,1) .or. &
       nint(test_array_2(ksizex_l+1,1,1,1)) &
       .ne. pid(modulo(ip_x+1, np_x), ip_y, ip_t)) then
     print *, "Negative x update failed on process", ip_x, ip_y, ip_t
  end if
  if (test_array(1,1,1,1) .ne. test_array(1,ksizey_l+1,1,1) .or. &
       nint(test_array_2(1,ksizey_l+1,1,1)) &
       .ne. pid(ip_x, modulo(ip_y+1, np_y), ip_t)) then
     print *, "Negative y update failed on process", ip_x, ip_y, ip_t
  end if
  if (test_array(1,1,1,1) .ne. test_array(1,1,ksizet_l+1,1) .or. &
       nint(test_array_2(1,1,ksizet_l+1,1)) &
       .ne. pid(ip_x, ip_y, modulo(ip_t+1, np_t))) then
     print *, "Negative t update failed on process", ip_x, ip_y, ip_t
  end if
  if (test_array(ksizex_l,1,1,1) .ne. test_array(0,1,1,1) .or. &
       nint(test_array_2(0,1,1,1)) &
       .ne. pid(modulo(ip_x-1, np_x), ip_y, ip_t)) then
     print *, "Positive x update failed on process", ip_x, ip_y, ip_t
  end if
  if (test_array(1,ksizey_l,1,1) .ne. test_array(1,0,1,1) .or. &
       nint(test_array_2(1,0,1,1)) &
       .ne. pid(ip_x, modulo(ip_y-1, np_y), ip_t)) then
     print *, "Positive y update failed on process", ip_x, ip_y, ip_t
  end if
  if (test_array(1,1,ksizet_l,1) .ne. test_array(1,1,0,1) .or. &
       nint(test_array_2(1,1,0,1)) &
       .ne. pid(ip_x, ip_y, modulo(ip_t-1, np_t))) then
     print *, "Positive t update failed on process", ip_x, ip_y, ip_t
  end if


#ifdef MPI
  call MPI_Finalize(ierr)
#endif
end program test_halo_4_real
  