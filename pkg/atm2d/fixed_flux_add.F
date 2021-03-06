#include "ctrparam.h"
#include "ATM2D_OPTIONS.h"

C     !INTERFACE:
      SUBROUTINE FIXED_FLUX_ADD( inMonth, wght0, wght1,
     &                   intime0, intime1, iftime, myIter, myThid)
C     *==========================================================*
C     | Add fixed flux files to the surface forcing fields. These|
c     | can be OBS fields or derived fields for anomaly coupling.|
C     *==========================================================*
        IMPLICIT NONE

C     === Global Atmos/Ocean/Seaice Interface Variables ===
#include "ATMSIZE.h"
#include "SIZE.h"
#include "GRID.h"
#include "EEPARAMS.h"
#include "THSICE_VARS.h"
#include "ATM2D_VARS.h"

C     !INPUT/OUTPUT PARAMETERS:
C     === Routine arguments ===
C     inMonth - current month
C     wght0, wght1   - weight of first and second month, respectively
C     intime0,intime1- month id # for first and second months
C     iftime - true -> prompts a reloading of data from disk
C     myIter - Ocean iteration number
C     myThid - Thread no. that called this routine.
      INTEGER inMonth
      _RL  wght0
      _RL  wght1
      INTEGER intime0
      INTEGER intime1
      LOGICAL iftime
      INTEGER myIter
      INTEGER myThid

C     LOCAL VARIABLES:
      _RL qfadj     ! temp variable for qflux adjustment
      INTEGER i,j   ! loop counters
C     save below in common block so continual reloading isn't necessary
      COMMON /OCEANMEAN/
     &                 tau0, tau1, tav0, tav1,
     &                 wind0, wind1, qnet0, qnet1,
     &                 evap0, precip0, runoff0
C     &                 evap0, evap1,
C     &                 precip0, precip1,
C     &                 runoff0, runoff1

      _RS  tau0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  tau1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  tav0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  tav1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  wind0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  wind1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  qnet0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  qnet1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  evap0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
C      _RS  evap1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  precip0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
C      _RS  precip1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
      _RS  runoff0(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)
C      _RS  runoff1(1-Olx:sNx+Olx,1-Oly:sNy+Oly,1,1)

      IF (ifTime) THEN

C      If the above condition is met then we need to read in
C      data for the period ahead and the period behind current time.

        WRITE(*,*) 'S/R FIXED_FLUX_ADD: Reading new data'
        IF ( tauuFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( tauuFile,tau0,intime0,
     &                      myIter,myThid )
          CALL READ_REC_XY_RS( tauuFile,tau1,intime1,
     &                      myIter,myThid )
        ENDIF
        IF ( tauvFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( tauvFile,tav0,intime0,
     &                      myIter,myThid )
          CALL READ_REC_XY_RS( tauvFile,tav1,intime1,
     &                      myIter,myThid )
        ENDIF
        IF ( windFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( windFile,wind0,intime0,
     &                      myIter,myThid )
          CALL READ_REC_XY_RS( windFile,wind1,intime1,
     &                      myIter,myThid )
        ENDIF
        IF ( qnetFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( qnetFile,qnet0,intime0,
     &                      myIter,myThid )
          CALL READ_REC_XY_RS( qnetFile,qnet1,intime1,
     &                      myIter,myThid )
        ENDIF
      ENDIF
      
      IF (new_mon) THEN
        WRITE(*,*) 'S/R FIXED_FLUX_ADD: Reading new EmPmR files'
        IF ( evapFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( evapFile,evap0,inMonth,
     &                      myIter,myThid )
C          CALL READ_REC_XY_RS( evapFile,evap1,intime1,
C     &                      myIter,myThid )
        ENDIF
        IF ( precipFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( precipFile,precip0,inMonth,
     &                      myIter,myThid )
C          CALL READ_REC_XY_RS( precipFile,precip1,intime1,
C     &                      myIter,myThid )
        ENDIF
        IF ( runoffFile .NE. ' '  ) THEN
          CALL READ_REC_XY_RS( runoffFile,runoff0,inMonth,
     &                      myIter,myThid )
C          CALL READ_REC_XY_RS( runoffFile,runoff1,intime1,
C     &                      myIter,myThid )
        ENDIF
        new_mon = .FALSE.
      ENDIF


C--   Interpolate and add to anomaly
      DO j=1,sNy
        DO i=1,sNx
         IF (maskC(i,j,1,1,1).EQ.1.) THEN

          fu_2D(i,j)= fu_2D(i,j) +
     &                (wght0*tau0(i,j,1,1) + wght1*tau1(i,j,1,1))
          fv_2D(i,j)= fv_2D(i,j) +
     &                (wght0*tav0(i,j,1,1) + wght1*tav1(i,j,1,1))
          wspeed_2D(i,j)= wspeed_2D(i,j) +
     &                (wght0*wind0(i,j,1,1) + wght1*wind1(i,j,1,1))

          qfadj = (wght0*qnet0(i,j,1,1) + wght1*qnet1(i,j,1,1))
          IF ( (qfadj .NE. 0. _d 0) .AND. 
     &       (iceMask(i,j,1,1) .LT. 0.999 _d 0)) THEN
               qneto_2D(i,j)= qneto_2D(i,j) + qfadj
     &                / (1. _d 0 - iceMask(i,j,1,1))
          ENDIF

C 9/08/06 assume evap is + in file, thus subtract
          IF (useObsEmP) THEN
            evapo_2D(i,j)= -evap0(i,j,1,1) 
            precipo_2D(i,j)= precip0(i,j,1,1)
            IF (iceMask(i,j,1,1) .NE. 0. _d 0) THEN
              evapi_2D(i,j)= -evap0(i,j,1,1)
              precipi_2D(i,j)= precip0(i,j,1,1) 
            ENDIF
          ELSE
            evapo_2D(i,j)= evapo_2D(i,j) -
     &                evap0(i,j,1,1) 
            precipo_2D(i,j)= precipo_2D(i,j) +
     &                precip0(i,j,1,1) 
            IF (iceMask(i,j,1,1) .NE. 0. _d 0) THEN
              evapi_2D(i,j)= evapi_2D(i,j) -
     &                evap0(i,j,1,1) 
              precipi_2D(i,j)= precipi_2D(i,j) +
     &                precip0(i,j,1,1) 
            ENDIF
          ENDIF

          IF (useObsRunoff) THEN
              runoff_2D(i,j)= runoff0(i,j,1,1) 
          ELSE
              runoff_2D(i,j)= runoff_2D(i,j) +
     &                runoff0(i,j,1,1)
          ENDIF
         ENDIF
        ENDDO
      ENDDO

      RETURN
      END

