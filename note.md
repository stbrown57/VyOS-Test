# Notes

## September 9 ,2025

The system was up from about 21:15 9/8 to 08:20 9/9. Then it was down from 08:20 to 10:00. The logs were save for review later, but the WAN highly-availability on the primary was delete to prevent the failover. The failover may have been a problem, and removing the configuration was suppose to remove that element from the environment. I did not shutdown the secondary interface and when connectivity was restored I notices the both the WAN on the primary and secondary had the IAP IP assigned. The MAC addresses are cloned and that probably causes that situation. 

Shutdown the secondary instance in order to test the stability of the primary VyOS instance. Shutting down the WAN interface on the secondary caused the WAN interface to fail as it did last night. Wait to see if it comes back on line after the next one of two renewals.

Configure the primary instance as cleanly as possible to test basic viability. 

1. Remove all high-availability
2. Statically set LAN interface address to 192.168.1.1
   