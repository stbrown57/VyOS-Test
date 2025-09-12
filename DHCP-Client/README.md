To configure a scheduled task on a VyOS 1.5 rolling release to run the operational command "renew dhcp interface eth0" every 40 minutes, you must first create a shell script containing the command and then configure the task scheduler to execute the script at the specified interval.

### 1\. Create a Shell Script

First, you need to create a script that contains the operational command. Since scheduled tasks in VyOS run as the `root` user, you should use a shebang line and source the `vbash` script template to ensure the VyOS command-line environment is properly configured. The command "renew dhcp" is not a standard VyOS command. The correct operational command to renew the DHCP lease is **`renew dhcp client interface eth0`**.

1.  Enter configuration mode:
    `configure`

2.  Create a directory for your scripts:
    `set system scripts-config-dir /config/scripts`

3.  Exit configuration mode to write the script file:
    `exit`

4.  Create the script file using `vi` or a similar editor:
    `vi /config/scripts/renew-dhcp-eth0.sh`

5.  Insert the following lines into the script file. Note that operational commands must be prefixed with `run` when used in a script:

    ```bash
    #!/bin/vbash
    source /opt/vyatta/etc/functions/script-template
    run renew dhcp client interface eth0
    ```

6.  Save and exit the editor.

7.  Make the script executable:
    `chmod +x /config/scripts/renew-dhcp-eth0.sh`

\<br\>

-----

\<br\>

### 2\. Configure the Task Scheduler

Next, you will configure the VyOS task scheduler to execute the script every 40 minutes.

1.  Enter configuration mode:
    `configure`

2.  Set up the scheduled task, specifying a task name, the interval, and the path to your executable script:
    `set system task-scheduler task renew-dhcp interval 40m executable path /config/scripts/renew-dhcp-eth0.sh`

3.  Commit and save the changes:
    `commit`
    `save`

The system will now run the `renew-dhcp-eth0.sh` script, which executes the DHCP renewal command, every 40 minutes.