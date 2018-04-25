@echo off

REM This file harvests files specified as needed by the CheckSUR tool for a computer with WU corruption
REM Run on a known good installation of the same version of Windows (32/64bit)
REM certain assumptions are made, which will be parameterised in due course ;-)
REM change the input filename and the drive the usb stick appears as manually for now

REM keep defined variables local; enable delayed expansion (use !! syntax instead of %% for late as possible assignment)
SETLOCAL ENABLEDELAYEDEXPANSION
SET me=%~n0

REM file counters
set found=0
set notfound=0

echo ===============================================================================
echo running Windows command script %me%
echo ===============================================================================

REM tokens 2/3/4/5 could be 'CSI Payload File Missing'
REM in which case, tokens 7 will be the filename and 8 the subfolder within c:\windows\winsxs\

REM tokens 2/3/4/5 could be 'CSI Manifest All Zeroes'
REM in which case, 7 will be the manifest filename including path from c:\windows

REM tokens 2/3/4 could be 'CBS MUM Corrupt'
REM tokens 2/3/4 could be 'CBS Catalog Corrupt'
REM in either case, Mums and cats must be kept together. token 6 will be the filename (Mum or cat) including path from
REM c:\Windows

REM tokens 2/3/4/5 could be 'CBS Watchlist Package Missing' in which case you need to manually go into the registry,
REM look for the keyname that is token 7, and delete the name that is token 8 (see notes)

REM tokens 2/3/4 could be 'CBS Registry Error' - don't know the fix for this yet

for /F "tokens=1-8" %%h in (CheckSURR63No19.txt) do (

rem echo token 6 is %%m

   if "%%h"=="(fix)" (

      rem this is a record of a fixed problem...
      echo ********* ABORT! Re-run CheckSUR until the log file has no fix records in it!
      echo ********* Applying these output files to your Windows installation may make corruption worse!

   ) else (
      if "%%h"=="(f)" (
   
         rem this record is a problem that needs a fix

         if "%%i"=="CSI" (
            if "%%j"=="Payload" (
               if "%%k"=="File" (
                  if "%%l"=="Missing" (
rem                  echo c:\windows\winsxs\%%o\%%n

                     if EXIST "c:\windows\winsxs\%%o\%%n" (
                        echo found payload file c:\windows\winsxs\%%o\%%n
rem
rem my robocopy syntax is now correct?; shd be <source dir> <destination dir> <filename> <options>
rem
                        rem copy the file to usb stick (check drive letter). /l lists only, /v verbose
rem                     robocopy c:\windows\winsxs\%%o\%%n l:\harvest\%%o\%%n /l/v
                        robocopy c:\windows\winsxs\%%o\ f:\harvest\files\%%o\ %%n 

                        set /A found=found+1
                        echo copy this file, keeping in the correct subfolder, into C:\Windows\winsxs - need to take ownership first

                     ) else (
                        echo Not Found file c:\windows\winsxs\%%o\%%n  
                        set /A notfound=notfound+1   
 
                     ) 
                     rem end payload file existence check
                  )
               )
            )
            rem end of check for Payload
            if "%%j"=="Manifest" (
               if "%%k"=="All" (
                  if "%%l"=="Zeros" (
rem                  echo c:\windows\%%n

                     if EXIST "c:\windows\%%n" (

                        echo ===
                        echo found manifest file c:\windows\%%n

                        rem strip the folder names winsxs\Manifests\ from the filename, need to use a variable.
                        rem the !! syntax uses delayed expansion, vbles assigned at execution not parse time.

                        set WinManfile=%%n
rem                     echo processing !WinManfile!

                        set WinMan=!WinManfile:~0,17!
rem                     echo path fragment !WinMan!

                        set WMfile=!WinManfile:~17!
rem                     echo filename !WMfile!
                        echo ===

                        if not "!WinMan!"=="winsxs\Manifests\" (

                           echo Something funny with !WinMan!, check the manifest path in CheckSUR.txt!
                        ) else (  

                           rem robocopy syntax is: <source dir> <destination dir> <filename> <options>
                           rem copy the file to usb stick (check drive letter). /l lists only, /v verbose

                           robocopy c:\windows\!WinMan! f:\harvest\files !WMfile! /v

                           set /A found=found+1
                           echo copy this manifest file to C:\Windows\Temp\CheckSUR\winsxs\manifests\ and rerun CheckSUR.

                        rem below ends the manifest path check   
                        )

                     ) else (
                        echo Not Found file c:\windows\%%n  
                        set /A notfound=notfound+1   
 
                     rem below ends the manifest file existence check
                     ) 
                  )
               )
            rem below ends the Manifest all zeroes check
            ) 

         )
         if "%%i"=="CBS" (
            echo CBS error found!
            if "%%k"=="Corrupt" (
               echo CBS Corruption found!
               
               if "%%j"=="MUM" (
                  echo problem with Mum %%m
               ) else (
                  if "%%j"=="Catalog" (
                     echo problem with cat %%m
                  )
               )
           
            )
            if "%%k"=="Missing" (
               echo CBS files missing! 

               if EXIST "c:\windows\%%m" (
                  echo found cat/mum file c:\windows\%%m
               ) else (
                  echo not found c:\windows\%%m
               )

rem check for special download  C:\Users\jenke001\Downloads\files
rem first remove servicing\Packages\ from the file path
               set packagepath=%%m
               set package=!packagepath:~19!
               echo looking for package !package!

               if EXIST "c:\Users\jenke001\Downloads\files\!package!" (
                  echo found cat/mum file c:\Users\jenke001\Downloads\files\!package!
                  set /A found=found+1
                  rem copy the file to usb stick (check drive letter). /l lists only, /v verbose

                  robocopy c:\Users\jenke001\Downloads\files\ f:\harvest\files !package! /v

               ) else (
                  echo not found c:\Users\jenke001\Downloads\files\!package!
                  set /A notfound=notfound+1   
               )

            )
            if "%%j"=="Registry" (
               echo Uh oh, registry...
            ) 

         rem below ends the check for CBS issues with Mums and cats   
         )

         echo ===============================================================================

      rem below ends the check for (f)
      )

   rem below ends the check for (fix)
   )

rem below ends the for loop over input file
)


rem report on results

set /A total=%found%+%notfound%

echo Processing finished: %total% files in total,
echo %found% files were found
echo %notfound% files were not found