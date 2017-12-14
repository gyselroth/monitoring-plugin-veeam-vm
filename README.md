# Monitoring Plugin: veeam-vm   

### Description

Monitor the backup status of a single machine made with veeam

### Usage

    Usage: check_vm_backup [options]

    Options:
      -vm       NAME of the machince to check (Not the job name)
      -warning  WARNING offset (s) of the successful backup end time [Default: 86400]
      -critical CRITICAL offset (s) of the successful backup end time [Default: 172800]
	  -type     TYPE of Backup. Choose between Backup- and Backupcopy Jobs [Default: Backup]

### Requirements
    * Windows Server
    * Powershell
    * Veeam
    * Veeam Powershell Plugins

### Install 

Copy check_vm_backup to your plugin folder (directly on you windows system where veeam is installed) 
and create a service/exec in your monitoring engine. 
