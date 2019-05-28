function parseVMdetails($vmProperties)
{
    # it's a NoteProperty!    
    #$vmProperties
    $vmProperties = $vmProperties.properties
    $VMdata = "" | Select VMName, CPU,MemoryMB, StorageMB, OrgVDC
    $VMdata.VMName = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.name"}).Value
    $VMdata.MemoryMB = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.memoryAllocationMb"}).Value
    $VMdata.CPU = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.vcpuCount"}).Value
    $VMdata.StorageMB = ($vmProperties.Psobject.properties | where {$_.Name -eq "vm.storageAllocationMb"}).Value
    $VMdata.OrgVDC = ($vmProperties.Psobject.properties | where {$_.Name -eq "vdc.name"}).Value

    #write-host $VMData 
    return $VMdata
}

$vCloudURL = "https://192.168.11.151/api/query?type=adminEvent&sortDesc=timeStamp&pageSize=50"
$accessToken = "adbb4fc25ff64e4381ebdf7cb1333e3e"

$header = @{}
    $header.Add("Accept",'application/*+xml;version=31.0')
    $header.Add("x-vcloud-authorization",$accessToken)

#[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
$r = Invoke-WebRequest -Uri $vCloudURL -Method Get -Headers $header -ContentType "application/xml"

$vmEvents = ([xml]$r.Content).QueryResultRecords.AdminEventRecord | where {$_.entityType -eq "vm"}
#$vmEvents = ([xml]$r.Content).QueryResultRecords.AdminEventRecord | where {$_.entityName -in ('vdcInstantiateVapp','vappUpdateVm','vappUndeployPowerOff')}

$report = @()
foreach ($vmEvent in $vmEvents)
{
    $data = ""| Select Date, OrgName, vmName, entity, CPU, Memory, Storage #,OrgVDC
    $data.Date = '{0:yyyy-MM-dd hh:mm:ss}' -f [datetime] $vmEvent.timeStamp
    $data.OrgName = $vmEvent.orgName
    $data.entity = $vmEvent.entity
    # parse VM Details
    #write-host $vmEvent.details
    $q = $vmEvent.details
    $parsedData = parseVMdetails -vmProperties ($vmEvent.details | ConvertFrom-JSON)
    $data.vmName = $parsedData.VMName
    $data.CPU = $parsedData.CPU
    $data.Memory = $parsedData.MemoryMB
    $data.Storage = $parsedData.StorageMB
    #$data.OrgVDC = $parsedData.OrgVDC
    $report += $data

}
$report | ft

#([xml]$r.Content).QueryResultRecords.AdminEventRecord | where {$_.entityName -in ('vdcInstantiateVapp','vappUpdateVm','vappUndeployPowerOff')}
# Should be entityType = vm