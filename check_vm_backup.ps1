#
# Check veeam backup status
#
# @author  Raffael Sahli <sahli@gyselroth.com>
# @license MIT, gyselroth GmbH 2017
#

param (
   [string]$vm=$FALSE,
   [string]$warning=86400,
   [string]$critical=172800,
   [string]$type="Backup"
)

asnp "VeeamPSSnapIn" -ErrorAction SilentlyContinue

if($vm -eq $FALSE) {
    echo "param -vm missing"
    exit 3
}

if($vm -eq $FALSE) {
    echo "param -type is missing and must either be Backup or Copy. Leave it empty for Backupjobs"
    exit 3
}

if($type -eq "Copy") {
    $type="BackupSync"
}

if($type -ne "Backup" -and $type -ne "Backupsync") {
    echo "parameter -type wrong, please check the spelling"
    exit 3
}

$now=[Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
 
foreach($job in (Get-VBRJob | ?{$_.JobType -eq $type})) {
    $session = $job.FindLastSession()

    if(!$session) {
        continue;
    }

    $object = $session.GetTaskSessions() | Where-Object {$_.Name -eq $vm}


    if($object) {
        $time=$session.CreationTime

        if($object.Status -eq "Warning") {            
            echo "vm backup $vm finished with warning in backup job $($job.Name) at $time"
            exit 1
        } elseif($object.Status -ne "Success" -and $object.Status -ne "InProgress" -and $object.Status -ne "Pending") {            
            echo "vm backup $vm failed with status $($object.Status)) in backup job $($job.Name) at $time"
            exit 2
        }
                
        $ts=[Math]::Floor([decimal](Get-Date($time).ToUniversalTime()-uformat "%s"))
        $diff = $now-$ts
        
        if($diff -ge $warning -and $diff -le $critical) {
            if($object.Status -eq "InProgress" -or $object.Status -eq "Pending") {
                echo "vm backup $vm is warning, backup is still in progress started at $time"
            } else {
                echo "vm backup $vm is warning, last backup at $time"
            }
            
            exit 1
        } elseif($diff -ge $critical) {
            if($object.Status -eq "InProgress" -or $object.Status -eq "Pending") {
                echo "vm backup $vm is critical, backup is still in progress started at $time"

            } else {
                echo "vm backup $vm is critical, last backup at $time"
            }
            
            exit 2
        } else {
            if($object.Status -eq "InProgress" -or $object.Status -eq "Pending") {
                echo "vm backup $vm is ok, backup ist currently in progress started at $time"
            } else {
                echo "vm backup $vm is ok, last backup at $time"            
            }
        
            exit 0
        }
    }
}

echo "no backup found for vm $vm"
exit 2