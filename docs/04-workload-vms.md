# Deploy the Workload Virtual Machines

## Purpose

This stage deploys the three workload virtual machines used to test routing through the Network Virtual Appliance:

* A web-tier VM
* An application-tier VM
* A data-tier VM

Each VM is placed in a different subnet.

## Virtual Machine Plan

| VM        | Operating system | Subnet      | Private IP   |
| --------- | ---------------- | ----------- | ------------ |
| `vm-web`  | Windows Server   | `snet-web`  | `10.30.10.4` |
| `vm-app`  | Windows Server   | `snet-app`  | `10.30.20.4` |
| `vm-data` | Windows Server   | `snet-data` | `10.30.30.4` |

These virtual machines do not require public IP addresses because Azure Run Command can execute PowerShell scripts through the Azure VM agent.

## 1. Create the Web VM

In the Azure Portal:

1. Search for **Virtual machines**.
2. Select **Create**.
3. Select **Azure virtual machine**.
4. Configure the following settings:

| Setting              | Value                              |
| -------------------- | ---------------------------------- |
| Resource group       | `rg-azure-nva-lab`                 |
| Virtual machine name | `vm-web`                           |
| Region               | Same region as the virtual network |
| Image                | Windows Server 2022 Datacenter     |
| Size                 | A small lab-compatible VM size     |
| Authentication type  | Password                           |
| Username             | Choose an administrative username  |
| Public inbound ports | None                               |

On the **Networking** tab, configure:

| Setting                    | Value          |
| -------------------------- | -------------- |
| Virtual network            | `vnet-nva-lab` |
| Subnet                     | `snet-web`     |
| Public IP                  | None           |
| NIC network security group | Basic          |
| Public inbound ports       | None           |

Do not associate a route table during this stage.

Select **Review + create**, and then select **Create**.

## 2. Configure the Web VM Private IP

After deployment:

1. Open `vm-web`.
2. Select **Networking**.
3. Open the attached network interface.
4. Select **IP configurations**.
5. Open `ipconfig1`.
6. Change the private IP allocation to **Static**.
7. Enter:

```text
10.30.10.4
```

8. Save the configuration.

## 3. Create the Application VM

Repeat the VM creation process using:

| Setting              | Value        |
| -------------------- | ------------ |
| Virtual machine name | `vm-app`     |
| Subnet               | `snet-app`   |
| Public IP            | None         |
| Private IP           | `10.30.20.4` |

After deployment, open the application VM network interface and change its private IP allocation to **Static**.

Set the private IP address to:

```text
10.30.20.4
```

## 4. Create the Data VM

Repeat the process using:

| Setting              | Value        |
| -------------------- | ------------ |
| Virtual machine name | `vm-data`    |
| Subnet               | `snet-data`  |
| Public IP            | None         |
| Private IP           | `10.30.30.4` |

After deployment, open the data VM network interface and configure this static private IP:

```text
10.30.30.4
```

## 5. Verify the VM Deployment

Open:

```text
Azure Portal → Virtual machines
```

Confirm that all four lab virtual machines are running:

| VM        | Expected private IP |
| --------- | ------------------- |
| `vm-nva`  | `10.30.5.4`         |
| `vm-web`  | `10.30.10.4`        |
| `vm-app`  | `10.30.20.4`        |
| `vm-data` | `10.30.30.4`        |

## 6. Test Run Command

Test Azure Run Command on each Windows VM.

Open:

```text
Virtual machine → Operations → Run command
```

Select:

```text
RunPowerShellScript
```

Run:

```powershell
Write-Output "Computer name: $env:COMPUTERNAME"

Write-Output "IPv4 configuration:"
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object {
        $_.IPAddress -like "10.30.*"
    } |
    Select-Object InterfaceAlias, IPAddress, PrefixLength

Write-Output "Default route:"
Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
    Select-Object InterfaceAlias, NextHop, RouteMetric
```

Confirm that the correct private IP appears on each VM.

Expected addresses:

```text
vm-web  → 10.30.10.4
vm-app  → 10.30.20.4
vm-data → 10.30.30.4
```

## 7. Network Security Groups

Keep the default Virtual Network communication rules during the initial lab setup.

Do not create custom subnet-to-subnet deny rules yet because the Linux NVA will enforce the east-west traffic policy.

Do not open RDP port `3389` to the internet unless it is specifically required. Azure Run Command can be used for most configuration tasks in this lab.

## Expected Result

At the end of this stage, the environment should contain:

```text
vnet-nva-lab — 10.30.0.0/16
├── snet-firewall — 10.30.5.0/24
│   └── vm-nva — 10.30.5.4
├── snet-web — 10.30.10.0/24
│   └── vm-web — 10.30.10.4
├── snet-app — 10.30.20.0/24
│   └── vm-app — 10.30.20.4
└── snet-data — 10.30.30.0/24
    └── vm-data — 10.30.30.4
```

The workload VMs are now deployed, but the application listeners, firewall policies, and route tables have not yet been configured.
