param([string] $user = "", 
      [string] $promptCred = "0",
      [string] $adminSession = "1",
      [string] $vmName = "WorkMachine",
      [string] $resourceGroupName = "Dev_do_not_delete"
)
"Connecting to Ressource Group..."
$ressourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName
"Starting VM..."
$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $ressourceGroup.ResourceGroupName
Start-AzureRmVM -Name $vm.Name -ResourceGroupName $ressourceGroup.ResourceGroupName 

"Getting Public IP Adress"
$nicName = $vm.Name + "-ip"
$VmIp = ((Get-AzureRmPublicIpAddress -ResourceGroupName $ressourceGroup.ResourceGroupName) | Where-Object {$_.Name -eq $nicName}).IpAddress

# Create an rdp file
$tmpfile = "temp.rdp"
"full address:s:" +$VmIp | Out-File $tmpfile -Force
"prompt for credentials:i:" + $promptCred | Out-File $tmpfile -Append
"administrative session:i:" + $adminSession | Out-File $tmpfile -Append
"username:s:" +$user | Out-File $tmpfile -Append
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

