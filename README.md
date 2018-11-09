# ConnectToVM
This Powershell Script is for those who have a Desktop VM/Linux SSH Server Running in Azure. It finds the VM Starts It and Open an RDP/SSH connection when ready. 

#How to:

```
connect_to_vm.ps1 -user [insert username] -vmName [insert VM Name] -resourceGroupName [Insert RessourceGroup Name] -promptCred [OPTIONAL Prompt for Credentials in RDP ] -subsctiptionId [Subscription name or ID] -connectionMethod [rdp or ssh]

```

