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
 
foreach($job in (Get-VBRJob | ?{$_.JobType -eq $type})) {
    $session = $job.FindLastSession()

    if(!$session) {
        continue;
    }

    $object = $session.GetTaskSessions() | Where-Object {$_.Name -eq $vm}

    if($object) {
        $time=$session.CreationTime

        $ts=[Math]::Floor([decimal](Get-Date($time).ToUniversalTime()-uformat "%s"))
        $diff = $now-$ts
		
		if($object.Status -eq "InProgress" -or $object.Status -eq "Pending") {
			if($diff -ge $runtime_warn -and $diff -le $runtime_crit) {
				echo "vm backup $vm is warning, backup is still in progress started at $time"
				exit 1
			} elseif($diff -ge $runtime_crit) {
				echo "vm backup $vm is critical, backup is still in progress started at $time"				
				exit 2
			} else {
				echo "vm backup $vm is still in progress started at $time"
				exit 0
			}
		} elseif($object.Status -eq "Success" -or $object.Status -eq "Warning") {
			if($diff -ge $last_warn -and $diff -le $last_crit) {
				echo "vm backup $vm is warning, last backup at $time"
				exit 1
			} elseif($diff -ge $last_crit) {
				echo "vm backup $vm is critical, last backup at $time"
				exit 2
			} else {
				echo "vm backup $vm is ok, last backup at $time"            
				exit 0
			}
		} elseif($object.Status -eq "Failed") {
			echo "vm backup $vm is critical, last backup at $time"	
			exit 2
		} else {
			echo "vm backup $vm is unknown, last backup at $time"
			exit 3
		}        
    }
}

echo "no backup session found for vm $vm"
exit 2
