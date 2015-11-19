<#

#>

function Enable-ClientSystemRestore {
    [CmdletBinding()]
    param(
    )

    try {
        Enable-ComputerRestore -Drive C: -ErrorAction Stop
        $createRestorePoint = $True
    }
    catch{
        $_
        Exit 1
    }

    #determine disk % free
    $DiskWMI = (Get-WmiObject win32_logicaldisk | Where-Object {$_.deviceID -eq 'C:'})
    $PercentFree = (($DiskWMI.freespace/$DiskWMI.Size) * 100)

    #if more than 20% free, enable system restore.
    if ($PercentFree -ge 20){
        try{
        $SetPercentDiskUsage = 'vssadmin resize shadowstorage /for=c: /on=c: /MaxSize=10%'
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
        $a = Invoke-Command {cmd /c $SetPercentDiskUsage}
        $string = 'Successfully'

            if ($a -match $string){
                #System restore was not enabled, was able to activate, set flag for restore point to true
                $createRestorePoint = $True
            }
            else {
                #System restore was not enabled, not able to activate, setting flag for restore point to false
                $createRestorePoint = $False
            }
        }
        catch{
            [System.Exception]
            $ResultCode = $_
            $ResultCode.Exception
            $LASTEXITCODE
        }
    }
    else{
        #System restore was not enabled, not enough disk space available to activate system restore
        $createRestorePoint = $False
        Write-Output 'Not enough disk space free to enable system restore'
    }
    

    #if flag $createRestorePoint = true then create a restore point, otherwise sys restore could not be enabled
    if ($createRestorePoint -eq $True){
        try{
            Checkpoint-Computer -description 'Self Heal Completed'
            Write-Output 'Restore point created'
        }
        catch{
            [System.Exception]
            $ResultCode = $_
            $ResultCode.Exception
        }
    }
    else{
       Write-Output 'Could not create restore point.'
    }
}

Enable-ClientSystemRestore
