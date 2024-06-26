      integer, parameter :: t_Brownian = 3
      integer, parameter :: t_Langevin = 4
      integer, parameter :: t_MTM      = 5
      integer, parameter :: t_Read     = 6

      integer, parameter :: t_VMC      = 7
      integer, parameter :: t_DMC      = 8
      integer, parameter :: t_SRMC     = 9
      integer, parameter :: t_FKMC     = 10
      integer, parameter :: t_PDMC     = 11

      integer, parameter :: t_None       = 21
      integer, parameter :: t_Simple     = 22
      integer, parameter :: t_Core       = 23
      integer, parameter :: t_Mu         = 24
      integer, parameter :: t_Mu_Nu      = 25
      integer, parameter :: t_Mur        = 26
      integer, parameter :: t_Qmckl      = 27
      integer, parameter :: t_Boys       = 28
      integer, parameter :: t_Boys_Handy = 29

      integer, parameter :: t_Stopped  = 0
      integer, parameter :: t_Queued   = 1
      integer, parameter :: t_Running  = 2
      integer, parameter :: t_Stopping = 3

      character*(32)     :: types(30) = &
      (/  '               ',   &
          '               ',   &
          'Brownian       ',   &
          'Langevin       ',   &
          '               ',   &
          '               ',   &
          'VMC            ',   &
          'DMC            ',   &
          'SRMC           ',   &
          'FKMC           ',   &
          'PDMC           ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          '               ',   &
          'None           ',   &
          'Simple         ',   &
          'Core           ',   &
          'Mu             ',   &
          'Mu_Nu          ',   &
          'Mur            ',   &
          'Qmckl          ',   &
          'Boys           ',   &
          'Boys_Handy     ',   &
          '               '/)     

