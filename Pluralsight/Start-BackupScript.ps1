function Start-BackupScript {
	[CmdletBinding()]
	Param(
		[Parameter()][String]$WatchFolder,
		[Parameter()][String]$DestinationFolder
	)
  Process {
    $filter = '*.*'                           
    $fsw = New-Object IO.FileSystemWatcher $WatchFolder, $filter -Property @{IncludeSubdirectories = $false;NotifyFilter = [IO.NotifyFilters]'FileName,LastWrite'} 
    $action = {
      $fileMissing = $false 
      $FileInUseMessage = $false 
      $copied = $false 
      $file = Get-Item $Args.FullPath 
      $dateString = Get-Date -format "_yyyy-MM-dd_HH-mm-ss" 
      $DestinationFolder = $event.MessageData 
      $DestinationFileName = $file.basename + $dateString + $file.extension 
      $resultfilename = Join-Path $DestinationFolder $DestinationFileName 
      Write-Output ""
      while(!$copied) { 
        try { 
          Move-Item -Path $file.FullName -Destination $resultfilename -ErrorAction Stop
          $copied = $true 
        }  
        catch [System.IO.IOException] { 
          if(!$FileInUseMessage) { 
            Write-Output "$(Get-Date -Format "yyyy-MM-dd @ HH:mm:ss") - $file in use. Waiting to move file"
            $FileInUseMessage = $true 
          } 
          Start-Sleep -s 1 
        }  
        catch [System.Management.Automation.ItemNotFoundException] { 
          $fileMissing = $true 
          $copied = $true 
        } 
      } 
      if($fileMissing) { 
        Write-Output "$(Get-Date -Format "yyyy-MM-dd @ HH:mm:ss") - $file not found!"
      } else { 
        Write-Output "$(Get-Date -Format "yyyy-MM-dd @ HH:mm:ss") - Moved $file to backup! `n`tFilename: `"$resultfilename`""
      }
    }
    $backupscript = Register-ObjectEvent -InputObject $fsw -EventName "Created" -Action $action -MessageData $DestinationFolder
	Get-Job $backupscript -Keep
    Write-Host "Started. WatchFolder: `"$($WatchFolder)`" DestinationFolder: `"$($DestinationFolder)`". Job is in: `$backupscript"
  }
}
Start-BackupScript -WatchFolder "C:\TEST\Test1" -DestinationFolder "C:\TEST\Test2"