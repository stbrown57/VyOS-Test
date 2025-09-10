To schedule a DHCP lease renewal in VyOS, you can use the built-in task scheduler, which is based on the standard UNIX cron system. This involves creating a script that runs the renewal commands and then scheduling that script to run at specific intervals. 
Step 1: Create the renewal script
First, you need to create a shell script that executes the necessary VyOS operational commands to renew the DHCP lease. This is typically done with the run renew dhcp interface <interface-name> command. 
Log in to your VyOS device via SSH.
Enter configuration mode:
sh
configure
Navigate to the script storage directory. The /config/scripts/ directory is the recommended location for user scripts, as it is persistent across reboots.
Create the script file using an editor like vi. For example, to create a script for the eth0 interface:
sh
edit system task-scheduler task renew_eth0 executable path /config/scripts/renew_eth0.sh
commit
save
Now, write the script. Enter the shell environment with the exit command and use sudo vi to create and edit the file.
sh
exit
sudo vi /config/scripts/renew_eth0.sh
Add the following content to the script, replacing eth0 with your actual interface name:
sh
#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

# Renew the DHCP lease for the specified interface
run renew dhcp interface eth0
Save and exit the editor.
Make the script executable:
sh
sudo chmod +x /config/scripts/renew_eth0.sh
 
Step 2: Configure the task scheduler
Now, schedule the script to run using the VyOS task scheduler.
Enter configuration mode on your VyOS device:
sh
configure
Set up a new task named renew_dhcp_lease. You can use either a cron-style specification or a simple interval.Option A: Using an interval (e.g., every 6 hours)
sh
set system task-scheduler task renew_dhcp_lease executable path /config/scripts/renew_eth0.sh
set system task-scheduler task renew_dhcp_lease interval 6h
Option B: Using a cron-style specification (e.g., at 3:30 a.m. daily)
sh
set system task-scheduler task renew_dhcp_lease executable path /config/scripts/renew_eth0.sh
set system task-scheduler task renew_dhcp_lease crontab-spec "30 3 * * *"
Commit and save your changes:
sh
commit
save
 
Step 3: Verify the configuration
You can check if the task is configured correctly with the following operational mode commands.
To show the current task scheduler configuration:
sh
run show configuration commands | grep task-scheduler
To list the system's cron jobs:
sh
run show task-scheduler
How to adapt the script for different needs
For multiple interfaces: Create separate scripts for each interface you need to renew, or modify the script to accept an interface name as an argument.
Add logging: Include logging within the script to monitor its execution and status. For example, add a line like logger "DHCP renew executed for eth0" to send a message to the system logs.
Add checks: To prevent unnecessary renewals, you could add logic to the script to check the lease status before forcing a renewal. 