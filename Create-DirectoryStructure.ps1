$Clients = "ABC", "NMO", "XYZ"
$Folders = "1. Vendor Info", "2. Network Infrastructure", "2. Network Infrastructure\1. Firewall Configs", "3. Reports"
$ClientArchive = "Z. Archived"
$OrphanFolder = "Z. Orphans"

$TargetFolder = "D:\Sample"

#Check if path already exists, if it doesn't, create it
function New-DirectoryIfNeeded {
    param (
        [Parameter(Mandatory = $true)]
        $Path
    )
    if (!(Test-Path $Path)) {
        New-Item $Path -ItemType Directory
    }
    return (Test-Path $Path)
}

if (Test-Path $TargetFolder) {
    ForEach ($Client in $Clients) {
        #Make the Client Folder
        $ClientFolder = New-DirectoryIfNeeded "$TargetFolder\$Client"
        if ($ClientFolder) {
            $Folders | ForEach-Object { 
                $Folder = New-DirectoryIfNeeded "$TargetFolder\$Client\$_"
            }
            #Create Orphan Folder
            $OrphanFolderObj = New-DirectoryIfNeeded "$TargetFolder\$Client\$OrphanFolder"
            #Move Orphaned Objects to the Orphan folder
            if ($OrphanFolderObj) {
                $ExistingFolders = Get-ChildItem "$TargetFolder\$Client"
                $ExistingFolders | ForEach-Object {
                    if ($_.Name -notin $Folders -and $_.Name -ne $OrphanFolder) {
                        $NewName = "$($_.Name) - Archived $(Get-Date -Format "yyyy-MM-dd_hhmmss")"
                        $NewObject = Rename-Item -Path $_.FullName -NewName $NewName -PassThru
                        Move-Item -Path $NewObject.FullName -Destination "$TargetFolder\$Client\$OrphanFolder\"
                    }
                }
            }

        }
    } 
    #Create Client Archive
    $ClientArchiveFolder = New-DirectoryIfNeeded "$TargetFolder\$ClientArchive"
    #Move any items from the root folder into archived if they aren't current clients
    if ($ClientArchiveFolder) {
        $ExistingClientFolders = Get-ChildItem $TargetFolder
        $ExistingClientFolders | ForEach-Object {
            if ($_.Name -notin $Clients -and $_.Name -ne $ClientArchive) {
                $NewName = "$($_.Name) - Archived $(Get-Date -Format "yyyy-MM-dd_hhmmss")"
                $NewObject = Rename-Item -Path $_.FullName -NewName $NewName -PassThru
                Move-Item -Path $NewObject.FullName -Destination "$TargetFolder\$ClientArchive"
            }
        }
    }
}

