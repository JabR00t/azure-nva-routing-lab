# Project Cleanup

## Purpose

This stage removes the Azure resources created for the NVA routing lab.

Azure resources such as virtual machines, managed disks, public IP addresses, and network services may continue generating charges while they exist.

All lab resources were placed inside one resource group:

```text
rg-azure-nva-lab
```

Deleting this resource group removes the complete lab environment.

## 1. Save the Project Evidence

Before deleting the environment, confirm that the required screenshots have been saved.

Recommended evidence includes:

* Virtual network and subnet configuration
* NVA private IP address
* Azure NIC IP forwarding
* Linux IP forwarding
* Firewall rules
* User-defined routes
* Route-table associations
* Network Watcher Next Hop results
* Effective routes
* Successful web-to-application test
* Successful application-to-data test
* Denied web-to-data test
* Firewall counters
* Denied-traffic logs
* Packet-capture results

## 2. Confirm the Resource Group Contents

In the Azure Portal:

1. Search for **Resource groups**.
2. Open `rg-azure-nva-lab`.
3. Select **Resources**.
4. Review the resources before deletion.

The resource group may contain:

```text
rg-azure-nva-lab
├── vnet-nva-lab
├── vm-nva
├── vm-web
├── vm-app
├── vm-data
├── Network interfaces
├── Managed disks
├── Network security groups
├── Public IP addresses
├── rt-web
├── rt-app
└── rt-data
```

Confirm that the resource group does not contain unrelated resources.

## 3. Delete the Resource Group Using the Azure Portal

In the Azure Portal:

1. Open `rg-azure-nva-lab`.
2. Select **Delete resource group**.
3. Enter the resource group name:

```text
rg-azure-nva-lab
```

4. Review the resources that will be deleted.
5. Confirm the deletion.

Deleting the resource group is permanent.

## 4. Optional Azure CLI Cleanup

The resource group can also be deleted using Azure CLI:

```bash
az group delete \
    --name rg-azure-nva-lab \
    --yes
```

To avoid waiting for the command to finish:

```bash
az group delete \
    --name rg-azure-nva-lab \
    --yes \
    --no-wait
```

## 5. Optional Azure PowerShell Cleanup

The resource group can be deleted using Azure PowerShell:

```powershell
Remove-AzResourceGroup `
    -Name "rg-azure-nva-lab" `
    -Force
```

## 6. Verify the Deletion

Using Azure CLI:

```bash
az group exists \
    --name rg-azure-nva-lab
```

Expected result after deletion:

```text
false
```

Using Azure PowerShell:

```powershell
Get-AzResourceGroup `
    -Name "rg-azure-nva-lab" `
    -ErrorAction SilentlyContinue
```

No resource group should be returned.

You can also search for `rg-azure-nva-lab` in the Azure Portal and confirm that it no longer exists.

## 7. Review Remaining Resources

After deleting the resource group, review the Azure Portal for unexpected resources.

Check:

* Virtual machines
* Managed disks
* Public IP addresses
* Network interfaces
* Network security groups
* Route tables
* Virtual networks
* Bastion resources
* Network Watcher packet-capture storage
* Storage accounts used for diagnostics or packet captures

Resources created in a different resource group will not be removed when `rg-azure-nva-lab` is deleted.
