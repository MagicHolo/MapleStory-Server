@echo off
@title MapleStory
set PATH=C:\Program Files\RedHat\java-1.8.0-openjdk-1.8.0.492-1\bin;%PATH%
set CLASSPATH=.;dist\*
java -Xmx2048m -Dwzpath=wz\ net.server.Server
pause