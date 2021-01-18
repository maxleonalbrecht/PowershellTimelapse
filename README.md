##  PowerShell Timelapse with Ffmpeg
### Features

- Automatic download and extraction of ffpmeg
- Just place your videos, which should be added to timeplase to *./Source*  folder
- There are being sorted by names

You can change the following variables to edit speed of the timelapse
```powershell
# - 0.50 = 2x | # - 0.10 = 10x | # - 0.05 = 50x | # - 0.01 = 100x
$speedUp="0.05"
# How much to trim off each sped-up clip. One frame @ 30fps = "00.03".
$trimAmount="00.12"
```
