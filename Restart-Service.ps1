param  
(  
    [Parameter (Mandatory = $false)]  
    [object] $WebhookData  
)

#login to Azure:
$connectionName = "AzureRunAsConnection"
try {
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
    else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

#Extract data from webhook
$AlertContext = (ConvertFrom-Json $WebhookData.RequestBody).data.alertContext
$computerName = $AlertContext.AffectedConfigurationItems
Write-Output "Computername: $computerName"

$vm = Get-AzVM | Where-Object Name -eq $computerName
$nicRef = Get-AzResource -ResourceId $vm.NetworkProfile.NetworkInterfaces.Id
$nic = Get-AzNetworkInterface -ResourceGroupName $nicRef.ResourceGroupName -Name $nicRef.Name
$publicIpRef = Get-AzResource -ResourceId $nic.IpConfigurations[0].PublicIpAddress.Id
$publicIp = Get-AzPublicIpAddress -Name $publicIpRef.Name -ResourceGroupName $publicIpRef.ResourceGroupName
$fqdn = $publicIp.DnsSettings.Fqdn
Write-Output "Connecting to VM: $($fqdn)"
$soptions = New-PSSessionOption -SkipCACheck -SkipCNCheck -SkipRevocationCheck
$cred = Get-AutomationPSCredential -Name 'aa-admin'
$serviceName = "spooler"
Invoke-Command -ComputerName $fqdn -Credential $cred -Port 5986 -UseSSL -SessionOption $soptions -ScriptBlock {
    $serviceStatus = (Get-Service -Name $using:serviceName ).Status
    if ($serviceStatus -eq "Stopped") {
        Write-Output "Starting service"
        Start-Service -Name $using:serviceName -Verbose
    }
}