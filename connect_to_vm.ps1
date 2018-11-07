#Requires -Version 6.0
#Requires -Modules AzureRM.Netcore

param([string] $user = "[Inster Username here]", 
      [string] $promptCred = "0",
      [string] $adminSession = "1",
      [string] $vmName = "[Insert VM name here]",
      [string] $resourceGroupName = "[Insert Ressource Group Name here]",
      [string] $subsctiptionId = "[Insert Subscription GUID HERE]"
)
"Connecting to Ressource Group..."

$AzureAcount = Get-AzureRmContext
Try {
    Set-AzureRmContext -Subscription $subsctiptionId -ErrorAction Stop
    $ressourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction Stop
}
Catch {
    # Account not connected
    "Login Needed"
    Connect-AzureRmAccount
    Set-AzureRmContext -Subscription $subsctiptionId -ErrorAction Stop
    $ressourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction Stop
}
"Starting VM..."
$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $ressourceGroup.ResourceGroupName
Start-AzureRmVM -Name $vm.Name -ResourceGroupName $ressourceGroup.ResourceGroupName 

"Getting Public IP Adress"
$nicName = $vm.Name + "-ip"
$nsgName = $vm.Name + "-nsg"
$port = 3389
$VmIp = ((Get-AzureRmPublicIpAddress -ResourceGroupName $ressourceGroup.ResourceGroupName) | Where-Object {$_.Name -eq $nicName}).IpAddress

"Changing NSG"
# https://docs.microsoft.com/en-us/azure/service-fabric/scripts/service-fabric-powershell-add-nsg-rule
$rulename = "Rdp-Rule"

"Getting Client IP"
$ClientIp = Invoke-RestMethod http://ipinfo.io/json | Select -exp ip



$nsg = Get-AzureRmNetworkSecurityGroup -Name $nsgName -ResourceGroupName $ressourceGroup.ResourceGroupName
"Removing Existing Rules"
Remove-AzureRmNetworkSecurityRuleConfig -Name $rulename -NetworkSecurityGroup $nsg -ErrorAction Continue
"Adding New NSG Rule"
$nsg | Add-AzureRmNetworkSecurityRuleConfig -Name $rulename -Description "Allow RDP" -Access Allow `
    -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix ($ClientIp + "/32") -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange $port



$nsg | Set-AzureRmNetworkSecurityGroup




# Create an rdp file
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
Remove-Item $tmpfile
