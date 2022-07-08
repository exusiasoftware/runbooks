Param(    
    [Parameter(Mandatory = $false)] 
    [String] $ResourceGroupName
)

Connect-AzAccount -Identity

if ($ResourceGroupName) { 
    Write-Output "Resource Group specified: $($ResourceGroupName)"
    $VMs = Get-AzVM -ResourceGroupName $ResourceGroupName
}
else { 
    Write-Output "No Resource Group specified"
    $VMs = Get-AzVM
}

foreach ($VM in $VMs) {
    try {
        Write-Output "Starting VM: $($VM.Name)"
        $VM | Start-AzVM -ErrorAction Stop
        Write-Output ($VM.Name + " has been started")
    }
    catch {
        Write-Output ($VM.Name + " failed to start")
    }
}