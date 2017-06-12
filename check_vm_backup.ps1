param (
   [string]$vm=$FALSE,
   [string]$warning=86400,
   [string]$critical=172800
)

asnp "VeeamPSSnapIn" -ErrorAction SilentlyContinue

if($vm -eq $FALSE) {
    echo "param -vm missing"
    exit 3
}

$now=[Math]::Floor([decimal](Get-Date(Get-Date).ToUniversalTime()-uformat "%s"))

foreach($job in (Get-VBRJob)) {
    $session = $job.FindLastSession()
    if(!$session) {
        continue;
    }
 
    $object = $Session.GetTaskSessions() | Where-Object {$_.Name -eq $vm}
    
    if($object) {
        $time=$session.EndTime

        if($object.Status -ne "Success") {
            echo "vm backup $vm failed with status $object.Status in backup job $job.Name at $time"
            exit 2
        }
                $ts=[Math]::Floor([decimal](Get-Date($time).ToUniversalTime()-uformat "%s"))
        $diff = $now-$ts
        
        if($diff -ge $warning -and $diff -le $critical) {
            echo "vm backup $vm is warning, last backup at $time"
            exit 1
        } elseif($diff -ge $critical) {
            echo "vm backup $vm is critical, last backup at $time"
            exit 2
        } else {
            echo "vm backup $vm is ok, last backup at $time"            
            exit 0
        }
    }
}

echo "no backup found for vm $vm"
exit 2
