!! ----------------------------------------------------------------------------------------------------------------------------- !!
!>
!! 2D wavenumber filtering
!!
!! @copyright
!!   Copyright 2013-2018 Takuto Maeda. All rights reserved. This project is released under the MIT license.
!<
!! ----------------------------------------------------------------------------------------------------------------------------- !!
module m_filt2d

  use m_std
  use m_fk
  implicit none
  public
  save


contains

  subroutine filt2d__lowpass ( nx, ny, dx, dy, img, kmax, np )

    integer,  intent(in)     :: nx
    integer,  intent(in)     :: ny
    real(SP), intent(in)     :: dx
    real(SP), intent(in)     :: dy
    real(SP), intent(inout)  :: img(nx,ny)
    real(SP), intent(in)     :: kmax
    integer,  intent(in)     :: np
    !! --
    integer                  :: nx2, ny2
    integer                  :: i, j
    real(DP),    allocatable :: xdom(:,:)
    complex(DP), allocatable ::  kdom(:,:)
    real(DP),    allocatable :: kx(:), ky(:)
    real(SP)                 :: k
    real(SP)                 :: H
    !! ----

    !! power of 2
    nx2  = 2 ** ceiling( log(dble(nx))/log(2.0_SP) )
    ny2  = 2 ** ceiling( log(dble(ny))/log(2.0_SP) )

    allocate( xdom(nx2,ny2), kdom(nx2,ny2) )
    allocate( kx(nx2), ky(ny2) )

    !! copy data
    xdom(:,:) = 0.0_DP
    xdom(1:nx,1:ny) = dble( img(1:nx,1:ny) )

    !! wavenumber spectrum
    call fk__x2k_2d( nx2, ny2, dble(dx), dble(dy), xdom, kdom, kx, ky )

    !! filtering
    do j=1, ny2
      do i=1, nx2

        !! absolute value of wavenumber
        k = sqrt( kx(i)**2 + ky(j)**2 )

        !! filter response
        H = 1 / sqrt( 1.0_DP + (k/kmax)**(2*np) )
        kdom(i,j) = kdom(i,j) * H

      end do
    end do

    !! back to the space domain
    call fk__k2x_2d( nx2, ny2, dble(dx), dble(dy), kdom, xdom )

    !! restore filtered data
    img(1:nx,1:ny) = real( xdom(1:nx,1:ny) )

    !! release temporal memory
    deallocate( xdom, kdom, kx, ky )

  end subroutine filt2d__lowpass



end module m_filt2d
