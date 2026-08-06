# Configure User-Defined Routes

## Purpose

This stage creates three Azure route tables and associates them with the workload subnets.

The routes override Azure's direct Virtual Network system routes and send traffic through the Linux Network Virtual Appliance.

The NVA uses this private IP address:

```text
10.30.5.4
```

## Route Table Plan

| Route table | Associated subnet |
| ----------- | ----------------- |
| `rt-web`    | `snet-web`        |
| `rt-app`    | `snet-app`        |
| `rt-data`   | `snet-data`       |

A separate route table is used for each workload subnet to maintain symmetric routing.

Do not associate a workload route table with `snet-firewall`.

## 1. Create the Web Route Table

In the Azure Portal:

1. Search for **Route tables**.
2. Select **Create**.
3. Configure:

| Setting                  | Value                              |
| ------------------------ | ---------------------------------- |
| Resource group           | `rg-azure-nva-lab`                 |
| Region                   | Same region as the virtual network |
| Name                     | `rt-web`                           |
| Propagate gateway routes | Yes                                |

4. Select **Review + create**.
5. Select **Create**.

Open `rt-web`, select **Routes**, and add these routes:

| Route name        | Destination type | Destination prefix | Next-hop type     | Next-hop address |
| ----------------- | ---------------- | ------------------ | ----------------- | ---------------- |
| `to-app`          | IP Addresses     | `10.30.20.0/24`    | Virtual appliance | `10.30.5.4`      |
| `to-data`         | IP Addresses     | `10.30.30.0/24`    | Virtual appliance | `10.30.5.4`      |
| `default-via-nva` | IP Addresses     | `0.0.0.0/0`        | Virtual appliance | `10.30.5.4`      |

### Associate `rt-web`

1. Open `rt-web`.
2. Select **Subnets**.
3. Select **Associate**.
4. Choose:

   * Virtual network: `vnet-nva-lab`
   * Subnet: `snet-web`
5. Select **OK**.

## 2. Create the Application Route Table

Create another route table:

```text
rt-app
```

Add these routes:

| Route name        | Destination prefix | Next-hop type     | Next-hop address |
| ----------------- | ------------------ | ----------------- | ---------------- |
| `to-web`          | `10.30.10.0/24`    | Virtual appliance | `10.30.5.4`      |
| `to-data`         | `10.30.30.0/24`    | Virtual appliance | `10.30.5.4`      |
| `default-via-nva` | `0.0.0.0/0`        | Virtual appliance | `10.30.5.4`      |

Associate `rt-app` with:

```text
snet-app
```

## 3. Create the Data Route Table

Create:

```text
rt-data
```

Add these routes:

| Route name        | Destination prefix | Next-hop type     | Next-hop address |
| ----------------- | ------------------ | ----------------- | ---------------- |
| `to-web`          | `10.30.10.0/24`    | Virtual appliance | `10.30.5.4`      |
| `to-app`          | `10.30.20.0/24`    | Virtual appliance | `10.30.5.4`      |
| `default-via-nva` | `0.0.0.0/0`        | Virtual appliance | `10.30.5.4`      |

Associate `rt-data` with:

```text
snet-data
```

## 4. Final Route Summary

### Web subnet

```text
10.30.20.0/24 → 10.30.5.4
10.30.30.0/24 → 10.30.5.4
0.0.0.0/0     → 10.30.5.4
```

### Application subnet

```text
10.30.10.0/24 → 10.30.5.4
10.30.30.0/24 → 10.30.5.4
0.0.0.0/0     → 10.30.5.4
```

### Data subnet

```text
10.30.10.0/24 → 10.30.5.4
10.30.20.0/24 → 10.30.5.4
0.0.0.0/0     → 10.30.5.4
```

## 5. Why Specific Routes Are Required

The default route:

```text
0.0.0.0/0
```

matches every destination, but it is less specific than routes for the Azure Virtual Network.

For example:

```text
10.30.20.0/24
```

is more specific than:

```text
0.0.0.0/0
```

The specific `/24` routes ensure that workload traffic is sent to the NVA instead of using Azure's direct system route.

## 6. Symmetric Routing

Routes must be configured in both directions.

For web-to-application communication:

```text
Forward path:
vm-web → vm-nva → vm-app

Return path:
vm-app → vm-nva → vm-web
```

The web route table contains a route to the application subnet, and the application route table contains a route back to the web subnet.

For application-to-data communication:

```text
Forward path:
vm-app → vm-nva → vm-data

Return path:
vm-data → vm-nva → vm-app
```

The application and data route tables therefore require routes to each other.

## 7. Important Warnings

Do not associate these route tables with:

```text
snet-firewall
```

The NVA subnet must retain a direct route to the workload subnets. Associating one of the workload route tables with the firewall subnet could create a routing loop.

Before associating the route tables, confirm that:

* Azure NIC IP forwarding is enabled on `vm-nva`.
* Linux IP forwarding is enabled.
* The NVA firewall rules are configured.
* The NVA private address is `10.30.5.4`.
* The application and data test listeners are running.

## 8. Verify Route-Table Associations

Open each route table and select **Subnets**.

Confirm:

| Route table | Associated subnet |
| ----------- | ----------------- |
| `rt-web`    | `snet-web`        |
| `rt-app`    | `snet-app`        |
| `rt-data`   | `snet-data`       |

Also open:

```text
vnet-nva-lab → Subnets
```

Verify:

| Subnet          | Route table |
| --------------- | ----------- |
| `snet-firewall` | None        |
| `snet-web`      | `rt-web`    |
| `snet-app`      | `rt-app`    |
| `snet-data`     | `rt-data`   |

## 9. Initial Connectivity Tests

After associating the route tables, run these tests.

### Web to application

Run on `vm-web`:

```powershell
curl.exe `
    --max-time 5 `
    http://10.30.20.4:8443/
```

Expected result:

```text
Allowed
```

### Application to data

Run on `vm-app`:

```powershell
curl.exe `
    --max-time 5 `
    http://10.30.30.4:1433/
```

Expected result:

```text
Allowed
```

### Web directly to data

Run on `vm-web`:

```powershell
curl.exe `
    --max-time 5 `
    --verbose `
    http://10.30.30.4:1433/
```

Expected result:

```text
Connection timeout or failure
```

The NVA should deny and log this connection.

## 10. Troubleshooting

### All connections fail

Check:

* NVA Azure NIC IP forwarding
* Linux `net.ipv4.ip_forward`
* NVA firewall rule order
* Correct next-hop IP
* Correct route-table associations

### Traffic bypasses the NVA

Check that the correct `/24` route exists.

For example, `rt-web` must contain:

```text
10.30.20.0/24 → 10.30.5.4
10.30.30.0/24 → 10.30.5.4
```

### One direction works but the connection fails

Check the destination subnet's return route.

For example, if web-to-application traffic fails, verify that `rt-app` contains:

```text
10.30.10.0/24 → 10.30.5.4
```

### Internet connectivity stops working

Check:

* The `0.0.0.0/0` route
* The NVA `MASQUERADE` rule
* NVA outbound connectivity
* Network Security Group rules
* DNS resolution

## Expected Result

At the end of this stage:

```text
snet-web
└── rt-web
    └── Traffic routed through 10.30.5.4

snet-app
└── rt-app
    └── Traffic routed through 10.30.5.4

snet-data
└── rt-data
    └── Traffic routed through 10.30.5.4

snet-firewall
└── No workload route table
```

All workload east-west traffic should now reach the NVA before being forwarded or denied.
