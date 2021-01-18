# - 0.50 = 2x | # - 0.10 = 10x | # - 0.05 = 50x | # - 0.01 = 100x
$speedUp="0.05"
# How much to trim off each sped-up clip. One frame @ 30fps = "00.03".
$trimAmount="00.12"

$baseDirectory = $global:PSScriptRoot
$ffmpegLocation = $baseDirectory + "\ffmpeg.exe"

$sourceFolder = $baseDirectory + "\Source\"
$destinationFolder = $baseDirectory + "\Destination\"

$destinationFolderCuttedFiles = $destinationFolder + "FasterVideos\"
$destinationFolderCroppedFiles = $destinationFolder + "CroppedVideos\"

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'
$destinationFileName = $destinationFolder + "timelapse.mp4"


##################################################
############## Prerequists Methods ###############
##################################################
function Kill-RunningFfmpeg
{
    if (Get-Process ffmpeg -ErrorAction SilentlyContinue)
    {
        Get-Process ffmpeg | Stop-Process ffmpeg -Force
    }
}

function Download-FfmpegToTempLocation($uri)
{
    Invoke-WebRequest $uri -OutFile $saveFfmpegTempLoactionZip
    if(!(test-path $tempPath))
    {
        New-Item -ItemType Directory -Force -Path $tempPath
    }

    Invoke-WebRequest $ffmpegLatestBuildUri -OutFile $saveFfmpegTempLoactionZip
}

function Extract-Ffmpeg()
{
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($saveFfmpegTempLoactionZip)

    $Filter = '*ffmpeg.exe'
    $zip.Entries | 
    Where-Object { $_.FullName -like $Filter } |
    ForEach-Object { 
        $fileName = $_.Name
        [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, "$baseDirectory\$fileName", $true)
    }
}

function Delete-TempFiles()
{
    try {
        Remove-Item $tempPath -Force -Recurse
    }
    catch {
         Write-Host "Could not delete $tempPath - maybe this path is in OneDrive?"   
    }
}
function Get-Ffmpeg
{
    #$ffmpegLatestBuildUri = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
    $tempPath = $baseDirectory + "/temp/"
    $saveFfmpegTempLoactionZip = $tempPath + "ffmpeg.zip"

    Kill-RunningFfmpeg
    Download-FfmpegToTempLocation($ffmpegLatestBuildUri)
    Extract-Ffmpeg
    Delete-TempFiles
}

##################################################
############## Start of Prerequists ##############
##################################################

if(!(Test-Path $ffmpegLocation))
{
    Get-Ffmpeg
}

##################################################
############## Done with Prerequists #############
##################################################

if(!(test-path $destinationFolderCuttedFiles))
{
      New-Item -ItemType Directory -Force -Path $destinationFolderCuttedFiles
}

if(!(test-path $destinationFolder))
{
      New-Item -ItemType Directory -Force -Path $destinationFolder
}

if(!(test-path $sourceFolder))
{
      New-Item -ItemType Directory -Force -Path $sourceFolder
}

if(!(test-path $destinationFolderCroppedFiles))
{
      New-Item -ItemType Directory -Force -Path $destinationFolderCroppedFiles
}

$listOfAllVideos = New-Object Collections.Generic.List[String]
 
Get-ChildItem $sourceFolder -recurse | Where-Object {$_.extension -eq ".mp4"} | ForEach-Object {
    $listOfAllVideos.Add($_)
}

if($listOfAllVideos.Count = 0)
{
    exit
}

$ffmpegArguments = "setpts=$speedUp*PTS"
$destinationVideoName =  $destinationFolderCuttedFiles + 'faster' + $video

foreach($video in $listOfAllVideos) 
{
    $source =  $sourceFolder+$video
    $destinationVideoName =  $destinationFolderCuttedFiles + 'faster' + $video

    &$ffmpegLocation -i $source -filter:v $ffmpegArguments -an $destinationVideoName
}

$listOfAllCuttedVideos = New-Object Collections.Generic.List[String]
 
Get-ChildItem $destinationFolderCuttedFiles -recurse | Where-Object {$_.extension -eq ".mp4"} | ForEach-Object {
    $listOfAllCuttedVideos.Add($_)
}

foreach($cuttedVideo in $listOfAllCuttedVideos)
{
    $sourceFasterVideo =  $destinationFolderCuttedFiles+$cuttedVideo
    $destinationVideoCroppedName = $destinationFolderCroppedFiles + 'cropped' + $cuttedVideo

    &$ffmpegLocation -i $sourceFasterVideo -ss $trimAmount -an $destinationVideoCroppedName
}

$listOfAllCroppedVideos = New-Object Collections.Generic.List[String]
 
Get-ChildItem $destinationFolderCroppedFiles -recurse | Where-Object {$_.extension -eq ".mp4"} | ForEach-Object {
    $listOfAllCroppedVideos.Add($_.FullName)
}

$concatListFilePath = $destinationFolder + "concatList.txt"

if((Test-Path $concatListFilePath))
{
    Remove-Item $concatListFilePath
}


$filePathListsOfVideos = $concatListFilePath

foreach($file in $listOfAllCroppedVideos)
{
   Write-Output "file '$file'" | Out-File -FilePath $filePathListsOfVideos -Append -Encoding Ascii
} 

&$ffmpegLocation -f concat -safe 0 -i $filePathListsOfVideos -c copy $destinationFileName