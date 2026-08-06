# Configure the Workload Test Listeners

## Purpose

This stage configures simple test services on the application and data virtual machines.

The services provide predictable TCP endpoints for validating routing and firewall policies through the Network Virtual Appliance.

| VM        | Operating system |   Private IP |  Test port | Purpose                       |
| --------- | ---------------- | -----------: | ---------: | ----------------------------- |
| `vm-app`  | Windows Server   | `10.30.20.4` | TCP `8443` | Application-tier test service |
| `vm-data` | Ubuntu Linux     | `10.30.30.4` | TCP `1433` | Data-tier test service        |

The service on TCP port `1433` is a basic Python HTTP server used only for connectivity testing. It is not a Microsoft SQL Server deployment.

## 1. Configure the Windows Application VM

The application VM runs IIS with an HTTP binding on TCP port `8443`.

Create the following script:

```text
scripts/windows/configure-app.ps1
```

### Run the application script

In the Azure Portal:

1. Open `vm-app`.
2. Select **Operations**.
3. Select **Run command**.
4. Select **RunPowerShellScript**.
5. Paste the contents of `configure-app.ps1`.
6. Select **Run**.

Expected output:

```text
HTTP status: 200
Application listener configuration completed.
```

### Validate the application listener

Run on `vm-app`:

```powershell
Test-NetConnection `
    -ComputerName localhost `
    -Port 8443
```

Expected result:

```text
TcpTestSucceeded : True
```

## 2. Configure the Linux Data VM

The Linux data VM runs a Python HTTP server on TCP port `1433`.

Create the following script:

```text
scripts/linux/configure-data.sh
```

### Run the data script

In the Azure Portal:

1. Open `vm-data`.
2. Select **Operations**.
3. Select **Run command**.
4. Select **RunShellScript**.
5. Paste the contents of `configure-data.sh`.
6. Select **Run**.

Expected results include:

```text
data-tier.service
LISTEN
Data Tier
Data listener configuration completed.
```

### Validate the data listener

Run on `vm-data`:

```bash
sudo systemctl is-active data-tier.service
sudo ss -lntp | grep ':1433'
curl --max-time 5 http://localhost:1433/
```

Expected service state:

```text
active
```

## 3. Run Baseline Network Tests

Before associating the custom route tables, test direct Azure VNet communication.

### Web VM to application VM

Run on the Windows `vm-web` using **RunPowerShellScript**:

```powershell
curl.exe `
    --max-time 5 `
    http://10.30.20.4:8443/
```

Expected result:

```text
Application Tier
```

### Application VM to data VM

Run on the Windows `vm-app`:

```powershell
curl.exe `
    --max-time 5 `
    http://10.30.30.4:1433/
```

Expected result:

```text
Data Tier
```

### Web VM directly to data VM

Run on `vm-web`:

```powershell
curl.exe `
    --max-time 5 `
    http://10.30.30.4:1433/
```

Before the custom routes and NVA firewall rules are applied, this connection may succeed because Azure uses direct VNet system routes between the subnets.

This provides a baseline result.

## 4. Expected Results After NVA Configuration

After configuring the route tables and Linux NVA firewall:

| Source   | Destination |       Port | Expected result   |
| -------- | ----------- | ---------: | ----------------- |
| `vm-web` | `vm-app`    | TCP `8443` | Allowed           |
| `vm-app` | `vm-data`   | TCP `1433` | Allowed           |
| `vm-web` | `vm-data`   | TCP `1433` | Denied and logged |

The allowed flows should follow these paths:

```text
vm-web → vm-nva → vm-app
vm-app → vm-nva → vm-data
```

The denied flow should reach the NVA and then be dropped:

```text
vm-web → vm-nva → blocked
```

## 5. Troubleshooting

### Application listener does not respond

On `vm-app`, check:

```powershell
Get-Service -Name W3SVC

Get-WebBinding `
    -Name "Default Web Site"

Get-NetFirewallRule `
    -DisplayName "Lab-Allow-App-TCP-8443"

Test-NetConnection `
    -ComputerName localhost `
    -Port 8443
```

### Data listener does not respond

On `vm-data`, check:

```bash
sudo systemctl status data-tier.service --no-pager
sudo journalctl -u data-tier.service --no-pager
sudo ss -lntp | grep ':1433'
curl --max-time 5 http://localhost:1433/
```

### Local test succeeds but remote test fails

Check:

* The destination VM private IP
* The Windows or Linux host firewall
* Azure Network Security Group rules
* Whether the service is listening on `0.0.0.0`
* The effective routes on both VMs
* The route-table association
* NVA firewall policy and rule order

## Expected Result

At the end of this stage:

```text
vm-web
  └── Used as the traffic source

vm-app — Windows Server — 10.30.20.4
  └── IIS listening on TCP 8443

vm-data — Ubuntu Linux — 10.30.30.4
  └── Python HTTP server listening on TCP 1433
```

The listeners are ready for the NVA routing and firewall tests.
