@echo off
chcp 65001 >nul
title BeamNG Online Server

cd /d "%~dp0server"
npm start
pause
