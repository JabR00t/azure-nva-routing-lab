# Network Foundation

## Purpose

This section creates the Azure network foundation for the lab:

* One resource group
* One virtual network
* Four subnets
* A dedicated subnet for the Network Virtual Appliance
* Three workload subnets for the web, application, and data tiers

## 1. Create the Resource Group

In the Azure Portal:

1. Search for **Resource groups**.
2. Select **Create**.
3. Enter the following settings:

| Setting        | Value                              |
| -------------- | ---------------------------------- |
| Subscription   | Select your Azure subscription     |
| Resource group | `rg-azure-nva-lab`                 |
| Region         | Select your preferred Azure region |

4. Select **Review + create**.
5. Select **Create**.

All resources in this lab should use the same resource group and Azure region.

## 2. Create the Virtual Network

1. Search for **Virtual networks**.
2. Select **Create**.
3. On the **Basics** tab, enter:

| Setting              | Value                                     |
| -------------------- | ----------------------------------------- |
| Subscription         | Select your Azure subscription            |
| Resource group       | `rg-azure-nva-lab`                        |
| Virtual network name | `vnet-nva-lab`                            |
| Region               | Use the same region as the resource group |

4. Open the **IP addresses** tab.
5. Set the IPv4 address space to:

```text
10.30.0.0/16
```

## 3. Create the Subnets

Remove any default subnet if it does not match the planned addressing.

Create the following four subnets:

| Subnet name     | IPv4 address range | Purpose                       |
| --------------- | ------------------ | ----------------------------- |
| `snet-firewall` | `10.30.5.0/24`     | Hosts the Linux NVA           |
| `snet-web`      | `10.30.10.0/24`    | Hosts the web-tier VM         |
| `snet-app`      | `10.30.20.0/24`    | Hosts the application-tier VM |
| `snet-data`     | `10.30.30.0/24`    | Hosts the data-tier VM        |

For this stage:

* Do not associate a route table.
* Do not configure subnet delegation.
* Do not add a NAT Gateway.
* Do not add service endpoints.
* Leave the default Azure DNS configuration enabled.

After adding all four subnets, select **Review + create**, and then select **Create**.

## 4. Verify the Deployment

Open:

```text
Virtual networks → vnet-nva-lab → Subnets
```

Confirm that all four subnets exist:

```text
snet-firewall    10.30.5.0/24
snet-web         10.30.10.0/24
snet-app         10.30.20.0/24
snet-data        10.30.30.0/24
```

Also verify the virtual network address space:

```text
10.30.0.0/16
```

## Expected Result

At the end of this stage, the Azure environment should contain:

```text
rg-azure-nva-lab
└── vnet-nva-lab — 10.30.0.0/16
    ├── snet-firewall — 10.30.5.0/24
    ├── snet-web — 10.30.10.0/24
    ├── snet-app — 10.30.20.0/24
    └── snet-data — 10.30.30.0/24
```

No virtual machines or route tables are created during this stage.
