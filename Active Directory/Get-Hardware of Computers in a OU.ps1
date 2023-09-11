#SET THE OU
$SEARCH_OU="OU=NAME_OU,DC=yourdomain,DC=com"

#SCRIPT
$ErrorActionPreference= 'silentlycontinue'
$namespace = "root\CIMV2"
$KeysArray = @()
Clear-host

Get-ADComputer -filter * -Searchbase $SEARCH_OU -Properties Description | ForEach-Object {
    #$Name = "localhost"
    $Name = $_.Name
    $Description = $_.Description
    write-host "PC: $Name" -NoNewline
    If (Test-Connection -ComputerName $Name -Count 1 -ErrorAction SilentlyContinue)
    {
        $Processor = gwmi win32_processor -ComputerName $Name | Select Name,LoadPercentage
        $ProcessorName = $Processor.Name
        $ProcessorName = $ProcessorName.Replace("Intel(R) Core(TM)","").Replace("CPU","").Replace(" ","").Split("@")[0]
        $ProcessorLoadPercentage = $Processor.LoadPercentage
        
        #---   DISK(S)   ---
        $Disks = gwmi Win32_diskdrive -ComputerName $Name | select model
        $DiskModels = $Disks.model -join ";"
        $Idle1=$DiskTime1=$T1=$Idle2=$DiskTime2=$T2=1
        $Disk = Get-WmiObject -class Win32_PerfRawData_PerfDisk_LogicalDisk -filter "name= 'C:'"
        [Double]$Idle1 = $Disk.PercentIdleTime
        [Double]$DiskTime1 = $Disk.PercentDiskTime
        [Double]$T1 = $Disk.TimeStamp_Sys100NS
        start-Sleep 10
        $Disk = Get-WmiObject -class Win32_PerfRawData_PerfDisk_LogicalDisk -filter "name= 'C:' "
        [Double]$Idle2 = $Disk.PercentIdleTime
        [Double]$DiskTime2 = $Disk.PercentDiskTime
        [Double]$T2 = $Disk.TimeStamp_Sys100NS
        $PercentIdleTime = [math]::Round((($Idle2 - $Idle1) / ($T2 - $T1)) * 100)
        $PercentDiskTime = [math]::Round((($DiskTime2 - $DiskTime1) / ($T2 - $T1)) * 100)

        #---   MEMORY   ---
        $memory = gwmi win32_operatingsystem -ComputerName $Name | select TotalVisibleMemorySize,FreePhysicalMemory
        $TotalVisibleMemorySize = [math]::Round((($memory.TotalVisibleMemorySize) / 1024)/ 1024)
        $PercentUsedMemory = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / ($memory.TotalVisibleMemorySize)) * 100)

        #Adicionando uma nova linha
        $KeyData = $null
        $KeyData = New-Object PSObject
        $KeyData | Add-Member -MemberType NoteProperty -Name "Name" -Value "$Name"
        $KeyData | Add-Member -MemberType NoteProperty -Name "Description" -Value "$Description"
        $KeyData | Add-Member -MemberType NoteProperty -Name "ProcessorName" -Value "$ProcessorName"
        $KeyData | Add-Member -MemberType NoteProperty -Name "CPU Usage" -Value "$ProcessorLoadPercentage"
        $KeyData | Add-Member -MemberType NoteProperty -Name "Disks" -Value "$DiskModels"
        $KeyData | Add-Member -MemberType NoteProperty -Name "PercentIdleTime" -Value "$PercentIdleTime"
        $KeyData | Add-Member -MemberType NoteProperty -Name "PercentDiskTime" -Value "$PercentDiskTime"
        $KeyData | Add-Member -MemberType NoteProperty -Name "Total Memory" -Value "$TotalVisibleMemorySize"
        $KeyData | Add-Member -MemberType NoteProperty -Name "Percent Memory Usage" -Value "$PercentUsedMemory"
        $KeysArray += $KeyData
        write-host " - OK" -ForegroundColor Green
        write-host "------------------------------------------------------------------------"
    }
    Else
    {
        write-host " - Sem acesso" -ForegroundColor Red
        write-host "------------------------------------------------------------------------"
    }
}
$KeysArray | ft