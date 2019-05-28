function parseVMdetails($vmProperties)
{
    # it's a NoteProperty!    
    
    $VMdata = "" | Select VMName, CPU, MemoryMB, StorageMB, OrgVDC
    $VMdata.VMName = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.name"}).Value
    $VMdata.MemoryMB = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.memoryAllocationMb"}).Value
    $VMdata.CPU = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.vcpuCount"}).Value
    $VMdata.StorageMB = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.storageAllocationMb"}).Value
    $VMdata.OrgVDC = ($vmProperties.Psobject.properties | where {$_.Name -eq "vdc.name"}).Value
    
    return $VMdata
}
$a
$z = parseVMdetails -vmProperties $a
$z