@echo off
echo Stopping Gradle daemons...
cd android
call gradlew --stop
cd ..
echo.
echo The build error indicated a process with PID 14764 was locking Gradle.
echo Attempting to terminate process with PID 14764...
taskkill /F /PID 14764
echo.
echo Done. Please try running your build again.
