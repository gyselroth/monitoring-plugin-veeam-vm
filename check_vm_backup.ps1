#
# Check veeam backup status
#
# @author  Raffael Sahli <sahli@gyselroth.com>
# @license MIT, gyselroth GmbH 2017-2019
#

param (
   [string]$vm=$FALSE,
   [string]$last_warn=86400,
   [string]$last_crit=172800,
   [string]$runtime_warn=10800,
   [string]$runtime_crit=21600,
   [string]$type="backup"
)

asnp "VeeamPSSnapIn" -ErrorAction SilentlyContinue

if($vm -eq $FALSE) {
    echo "param -vm missing"
    exit 3
}

if($type -eq "copy") {
    $type="backupsync"
}

if($type -ne "backup" -and $type -ne "backupsync") {
    echo "param -type accepts backup or copy as value"
    exit 3
}

$now=[Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))
$last = ($last_crit / 60 / 60) * -1

$last_status = 4;
$last_session;
$last_time;

foreach($session in (Get-VBRBackupSession | Where-Object {$_.CreationTime -ge (Get-Date).addhours($last)} | Sort creationtime)) {
    $object = $session.GetTaskSessions() | Where-Object {$_.Name -eq $vm}


    if($object) {
        $time=$session.CreationTime
        $ts=[Math]::Floor([decimal](Get-Date($time).ToUniversalTime()-uformat "%s"))
        $diff = $now-$ts
        $name = $session.name
        
        if($object.Status -eq "InProgress" -or $object.Status -eq "Pending") {
            if($diff -ge $runtime_warn -and $diff -le $runtime_crit) {
                echo "vm backup $vm is warning, backup is still in progress started at $time from session $name"
                exit 1
            } elseif($diff -ge $runtime_crit) {
                echo "vm backup $vm is critical, backup is still in progress started at $time from session $name"              
                exit 2
            } else {
                echo "vm backup $vm is still in progress started at $time from session $name"
                exit 0
            }
        } elseif($object.Status -eq "Success" -or $object.Status -eq "Warning") {		
            if($diff -ge $last_warn -and $diff -le $last_crit) {
                $temp = 0
            } elseif($diff -ge $last_crit) {
                $temp = 0
            } else {
                $temp = 0
            }
        } elseif($object.Status -eq "Failed") {
            $temp = 2
        } else {
            $temp = 3
        }        

        if($temp -le $last_status) {
            $last_time = $time;
            $last_status = $temp;
            $last_session = $session.name
        }
    }
}

if($last_status -eq 1) {
    echo "vm backup $vm is warning, last backup at $last_time from session $last_session"
    exit 1
} elseif($last_status -eq 2) {
    echo "vm backup $vm is critical, last backup at $last_time from session $last_session"
    exit 2
} elseif($last_status -eq 0) {
    echo "vm backup $vm is ok, last backup at $last_time from session $last_session"            
    exit 0
} elseif($last_status -eq 3) {
    echo "vm backup $vm is unknown, last backup at $last_time from session $last_session"            
    exit 3
}

echo "no backup session found for vm $vm"
exit 2
