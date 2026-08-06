# Prerequisites and Resource Plan

## Prerequisites

Before starting this lab, you need:

* An active Microsoft Azure subscription
* Permission to create virtual networks, virtual machines, network interfaces, route tables, public IP addresses, and Network Watcher resources
* Access to the Azure Portal
* Git installed locally
* A GitHub account
* Basic knowledge of Azure networking
* Basic familiarity with PowerShell and Linux commands

## Azure Resources

The lab uses the following resources:

| Resource                | Name               | Purpose                                           |
| ----------------------- | ------------------ | ------------------------------------------------- |
| Resource group          | `rg-azure-nva-lab` | Contains all lab resources                        |
| Virtual network         | `vnet-nva-lab`     | Provides the private network                      |
| Firewall subnet         | `snet-firewall`    | Hosts the Linux NVA                               |
| Web subnet              | `snet-web`         | Hosts the web-tier VM                             |
| Application subnet      | `snet-app`         | Hosts the application-tier VM                     |
| Data subnet             | `snet-data`        | Hosts the data-tier VM                            |
| Linux NVA               | `vm-nva`           | Routes, filters, and logs traffic                 |
| Web VM                  | `vm-web`           | Generates web-tier traffic                        |
| Application VM          | `vm-app`           | Listens on TCP port 8443                          |
| Data VM                 | `vm-data`          | Listens on TCP port 1433                          |
| Web route table         | `rt-web`           | Routes web-subnet traffic through the NVA         |
| Application route table | `rt-app`           | Routes application-subnet traffic through the NVA |
| Data route table        | `rt-data`          | Routes data-subnet traffic through the NVA        |

## IP Address Plan

| Component                 | Address         |
| ------------------------- | --------------- |
| Virtual network           | `10.30.0.0/16`  |
| Firewall subnet           | `10.30.5.0/24`  |
| NVA private IP            | `10.30.5.4`     |
| Web subnet                | `10.30.10.0/24` |
| Web VM private IP         | `10.30.10.4`    |
| Application subnet        | `10.30.20.0/24` |
| Application VM private IP | `10.30.20.4`    |
| Data subnet               | `10.30.30.0/24` |
| Data VM private IP        | `10.30.30.4`    |

## Operating Systems

| VM        | Operating system                |
| --------- | ------------------------------- |
| `vm-nva`  | Ubuntu Server                   |
| `vm-web`  | Windows Server or Ubuntu Server |
| `vm-app`  | Windows Server                  |
| `vm-data` | Windows Server or Ubuntu Server |

In this implementation, the application VM is a Windows Server VM. PowerShell commands are therefore used to configure and test its application listener.

## Security Notes

This project is intended for learning purposes.

Do not commit the following information to GitHub:

* Azure passwords
* SSH private keys
* Azure subscription IDs
* Tenant IDs
* Access tokens
* Private certificates
* Public IP addresses that you consider sensitive
* Files containing credentials or secrets

Use strong passwords and restrict management access to your own public IP address whenever possible.

## Cost Management

Azure virtual machines, disks, public IP addresses, Bastion, and other resources may generate charges.

Delete the resource group after completing the lab:

```text
rg-azure-nva-lab
```

Deleting the resource group removes the resources contained inside it.
