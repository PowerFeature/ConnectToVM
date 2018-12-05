# Updated to match breaking changed in AzureRM -> Az
#Requires -Version 6.0
#Requires -Modules Az

param([string] $user = "[Insert Username here]", 
      [string] $promptCred = "0",
      [string] $adminSession = "1",
      [string] $vmName = "[Insert VM name here]",
      [string] $resourceGroupName = "[Insert Ressource Group Name here]",
      [string] $connectionMethod = "rdp",
      [string] $subsctiptionId = "[Insert Subscription NAME or GUID HERE]"
)
"Connecting to Ressource Group..."
$AzureAcount = Get-AzContext
Try {
      "Setting Subscription ..."
      
      Set-AzContext -Subscription $subsctiptionId -ErrorAction Stop > $null
      "Getting ressource group ..."
      $ressourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop
}
Catch {
    # Account not connected
    "Login Needed"
    Connect-AzAccount
    "Setting Subscription ..."
    Set-AzContext -Subscription $subsctiptionId -ErrorAction Stop > $null
    "Getting ressource group ..."

    $ressourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction Stop
}
"Starting VM..."
$vm = Get-AzVM -Name $vmName -ResourceGroupName $ressourceGroup.ResourceGroupName
Start-AzVM -Name $vm.Name -ResourceGroupName $ressourceGroup.ResourceGroupName

"Getting VM Public IP Adress"
$nicName = $vm.Name + "-ip"
$nsgName = $vm.Name + "-nsg"

$port = 3389
If ($connectionMethod -eq 'ssh') {
      $port = 22
}
$VmIp = ((Get-AzPublicIpAddress -ResourceGroupName $ressourceGroup.ResourceGroupName) | Where-Object {$_.Name -eq $nicName}).IpAddress

"Changing NSG"
# https://docs.microsoft.com/en-us/azure/service-fabric/scripts/service-fabric-powershell-add-nsg-rule
$rulename = ($connectionMethod + "-Rule")

"Getting Client IP"
$ClientIp = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip
("Client Public IP is :" + $ClientIp)

$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ressourceGroup.ResourceGroupName
"Removing Existing Rule if exists ..."
Remove-AzNetworkSecurityRuleConfig -Name $rulename -NetworkSecurityGroup $nsg -ErrorAction Continue > $null
"Adding New NSG Rule"
$nsg | Add-AzNetworkSecurityRuleConfig -Name $rulename -Description "Allow RDP" -Access Allow `
    -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix ($ClientIp + "/32") -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $port > $null
"Updating NSG"
$nsg | Set-AzNetworkSecurityGroup



If ($connectionMethod -eq 'rdp') {
# Create an rdp file
"Creating RDP file"
$tmpfile = "temp.rdp"
"full address:s:" + $VmIp | Out-File $tmpfile -Force
"prompt for credentials:i:" + $promptCred | Out-File $tmpfile -Append
"administrative session:i:" + $adminSession | Out-File $tmpfile -Append
"username:s:" + $user | Out-File $tmpfile -Append
If ($IsWindows) {
    Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList $tmpfile
} 
Else {
    If ($IsMacOS) {
        open $tmpfile
    }
}
Start-Sleep -Seconds 5
"Cleaning Up ..."
#Remove-Item $tmpfile      
}
Else {
      ssh ($user + "@" + $VmIp) 
      "Deleting NSG rule"
      $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ressourceGroup.ResourceGroupName
      "Removing Existing Rule if exists ..."
      Remove-AzNetworkSecurityRuleConfig -Name $rulename -NetworkSecurityGroup $nsg -ErrorAction Continue > $null
      "Updating NSG"
      $nsg | Set-AzNetworkSecurityGroup > $null
}
