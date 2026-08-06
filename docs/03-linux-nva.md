# Deploy the Linux Network Virtual Appliance

## Purpose

This stage deploys an Ubuntu virtual machine that will operate as the Network Virtual Appliance.

The NVA will later:

* Receive traffic from the workload subnets
* Forward packets to their destinations
* Apply firewall rules
* Log denied traffic
* Provide outbound network address translation

## NVA Configuration

| Setting                 | Value             |
| ----------------------- | ----------------- |
| Virtual machine name    | `vm-nva`          |
| Operating system        | Ubuntu Server LTS |
| Virtual network         | `vnet-nva-lab`    |
| Subnet                  | `snet-firewall`   |
| Private IP address      | `10.30.5.4`       |
| Private IP allocation   | Static            |
| Azure NIC IP forwarding | Enabled           |
| Linux IP forwarding     | Enabled           |

## 1. Create the Virtual Machine

In the Azure Portal:

1. Search for **Virtual machines**.
2. Select **Create**.
3. Select **Azure virtual machine**.
4. Enter the following settings:

| Setting              | Value                              |
| -------------------- | ---------------------------------- |
| Resource group       | `rg-azure-nva-lab`                 |
| Virtual machine name | `vm-nva`                           |
| Region               | Same region as the virtual network |
| Image                | Ubuntu Server LTS                  |
| Size                 | A small lab-compatible VM size     |
| Authentication type  | SSH public key                     |
| Username             | Choose an administrative username  |

Under **Inbound port rules**, select:

```text
None
```

Run Command can be used to configure the VM without opening SSH access from the internet.

## 2. Configure Networking

Open the **Networking** tab and configure:

| Setting                    | Value                     |
| -------------------------- | ------------------------- |
| Virtual network            | `vnet-nva-lab`            |
| Subnet                     | `snet-firewall`           |
| Public IP                  | Standard static public IP |
| NIC network security group | Basic                     |
| Public inbound ports       | None                      |

The public IP provides explicit outbound internet connectivity for the NVA. It does not make services reachable unless the Network Security Group permits inbound traffic.

Select **Review + create**, and then select **Create**.

## 3. Configure the Static Private IP

After the VM deployment finishes:

1. Open `vm-nva`.
2. Select **Networking**.
3. Open the attached network interface.
4. Select **IP configurations**.
5. Open the primary IP configuration, normally `ipconfig1`.
6. Change **Private IP address settings** to **Static**.
7. Enter:

```text
10.30.5.4
```

8. Save the configuration.

The virtual machine may restart after its private IP configuration changes.

## 4. Enable Azure NIC IP Forwarding

Open Azure Cloud Shell and select PowerShell.

Run:

```powershell
$resourceGroup = "rg-azure-nva-lab"
$vmName = "vm-nva"

$vm = Get-AzVM `
    -ResourceGroupName $resourceGroup `
    -Name $vmName

$nicId = $vm.NetworkProfile.NetworkInterfaces[0].Id

$nic = Get-AzNetworkInterface -ResourceId $nicId

$nic.EnableIPForwarding = $true

$nic | Set-AzNetworkInterface
```

Verify the setting:

```powershell
(Get-AzNetworkInterface -ResourceId $nicId).EnableIPForwarding
```

Expected result:

```text
True
```

## 5. Enable Linux IP Forwarding

In the Azure Portal:

1. Open `vm-nva`.
2. Select **Operations**.
3. Select **Run command**.
4. Select **RunShellScript**.
5. Paste and run:

```bash
sudo tee /etc/sysctl.d/99-nva-forwarding.conf >/dev/null <<'EOF'
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo "IP forwarding status:"
sysctl net.ipv4.ip_forward
```

Expected output:

```text
net.ipv4.ip_forward = 1
```

The file under `/etc/sysctl.d/` makes the setting persistent after the VM restarts.

## 6. Verify the NVA Network Configuration

Use **RunShellScript** again:

```bash
echo "Private IPv4 addresses:"
ip -4 address show

echo
echo "Routing table:"
ip route

echo
echo "IP forwarding:"
sysctl net.ipv4.ip_forward
```

Confirm that:

* The VM has an address in `10.30.5.0/24`
* Its planned private address is `10.30.5.4`
* Linux IP forwarding equals `1`
* Azure NIC IP forwarding equals `True`

## Expected Result

At the end of this stage:

```text
snet-firewall — 10.30.5.0/24
└── vm-nva — 10.30.5.4
    ├── Azure NIC IP forwarding: Enabled
    └── Linux IP forwarding: Enabled
```

The NVA can forward packets, but firewall policies and user-defined routes have not been configured yet.
