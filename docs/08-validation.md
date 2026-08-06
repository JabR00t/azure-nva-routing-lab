# Validate Routing and Firewall Behavior

## Purpose

This stage confirms that:

* Workload traffic uses the Linux NVA at `10.30.5.4`.
* Forward and return traffic follow symmetric paths.
* Web-to-application traffic on TCP `8443` is allowed.
* Application-to-data traffic on TCP `1433` is allowed.
* Direct web-to-data traffic is denied and logged.
* The correct user-defined routes appear in each VM's effective routes.

## Expected Traffic Policy

| Source    | Destination |           Port | Expected result     |
| --------- | ----------- | -------------: | ------------------- |
| `vm-web`  | `vm-app`    |     TCP `8443` | Allowed             |
| `vm-app`  | `vm-web`    | Return traffic | Allowed through NVA |
| `vm-app`  | `vm-data`   |     TCP `1433` | Allowed             |
| `vm-data` | `vm-app`    | Return traffic | Allowed through NVA |
| `vm-web`  | `vm-data`   |     TCP `1433` | Denied and logged   |

## 1. Verify the Next Hop

In the Azure Portal:

1. Search for **Network Watcher**.
2. Under **Network diagnostic tools**, select **Next hop**.
3. Select the subscription and resource group.
4. Select the source virtual machine.
5. Select its network interface.
6. Enter the destination private IP.
7. Select **Next hop**.

### Web-to-application path

Enter:

| Setting        | Value        |
| -------------- | ------------ |
| Source VM      | `vm-web`     |
| Destination IP | `10.30.20.4` |

Expected result:

```text
Next-hop type: VirtualAppliance
Next-hop IP address: 10.30.5.4
```

### Application-to-web return path

Enter:

| Setting        | Value        |
| -------------- | ------------ |
| Source VM      | `vm-app`     |
| Destination IP | `10.30.10.4` |

Expected result:

```text
Next-hop type: VirtualAppliance
Next-hop IP address: 10.30.5.4
```

These two results confirm symmetric routing for the web-to-application connection.

### Application-to-data path

Enter:

| Setting        | Value        |
| -------------- | ------------ |
| Source VM      | `vm-app`     |
| Destination IP | `10.30.30.4` |

Expected result:

```text
Next-hop type: VirtualAppliance
Next-hop IP address: 10.30.5.4
```

### Data-to-application return path

Enter:

| Setting        | Value        |
| -------------- | ------------ |
| Source VM      | `vm-data`    |
| Destination IP | `10.30.20.4` |

Expected result:

```text
Next-hop type: VirtualAppliance
Next-hop IP address: 10.30.5.4
```

These two results confirm symmetric routing for the application-to-data connection.

### Web-to-data denied path

Enter:

| Setting        | Value        |
| -------------- | ------------ |
| Source VM      | `vm-web`     |
| Destination IP | `10.30.30.4` |

Expected result:

```text
Next-hop type: VirtualAppliance
Next-hop IP address: 10.30.5.4
```

The Next Hop result should still show the NVA.

Next Hop only confirms where Azure sends the packet. The Linux firewall decides whether the NVA forwards or denies it.

## 2. Next Hop Validation Table

Complete this table while performing the tests:

| Source    | Destination  | Expected next hop | Actual next hop | Status |
| --------- | ------------ | ----------------- | --------------- | ------ |
| `vm-web`  | `10.30.20.4` | `10.30.5.4`       |                 |        |
| `vm-app`  | `10.30.10.4` | `10.30.5.4`       |                 |        |
| `vm-app`  | `10.30.30.4` | `10.30.5.4`       |                 |        |
| `vm-data` | `10.30.20.4` | `10.30.5.4`       |                 |        |
| `vm-web`  | `10.30.30.4` | `10.30.5.4`       |                 |        |
| `vm-data` | `10.30.10.4` | `10.30.5.4`       |                 |        |

## 3. Review Effective Routes

Review the effective routes for each workload VM.

In the Azure Portal:

1. Open the virtual machine.
2. Select **Networking**.
3. Open the VM's network interface.
4. Select **Effective routes**.
5. Wait for Azure to load the route list.

### Expected routes for `vm-web`

Confirm that the effective routes include:

| Destination     | Next-hop type     | Next-hop IP |
| --------------- | ----------------- | ----------- |
| `10.30.20.0/24` | Virtual appliance | `10.30.5.4` |
| `10.30.30.0/24` | Virtual appliance | `10.30.5.4` |
| `0.0.0.0/0`     | Virtual appliance | `10.30.5.4` |

### Expected routes for `vm-app`

Confirm:

| Destination     | Next-hop type     | Next-hop IP |
| --------------- | ----------------- | ----------- |
| `10.30.10.0/24` | Virtual appliance | `10.30.5.4` |
| `10.30.30.0/24` | Virtual appliance | `10.30.5.4` |
| `0.0.0.0/0`     | Virtual appliance | `10.30.5.4` |

### Expected routes for `vm-data`

Confirm:

| Destination     | Next-hop type     | Next-hop IP |
| --------------- | ----------------- | ----------- |
| `10.30.10.0/24` | Virtual appliance | `10.30.5.4` |
| `10.30.20.0/24` | Virtual appliance | `10.30.5.4` |
| `0.0.0.0/0`     | Virtual appliance | `10.30.5.4` |

The list may also contain Azure system routes. Focus on the active user-defined routes whose next-hop type is **Virtual appliance**.

## 4. Test Web-to-Application Traffic

On the Windows `vm-web`, open:

```text
Operations → Run command → RunPowerShellScript
```

Run:

```powershell
$Uri = "http://10.30.20.4:8443/"

Write-Output "Testing Web to Application..."
Write-Output "Destination: $Uri"

curl.exe `
    --max-time 5 `
    --fail `
    --show-error `
    $Uri

if ($LASTEXITCODE -eq 0) {
    Write-Output "PASS: Web-to-Application traffic is allowed."
}
else {
    Write-Output "FAIL: Web-to-Application traffic did not succeed."
}
```

Expected result:

```text
Application Tier
PASS: Web-to-Application traffic is allowed.
```

## 5. Test Application-to-Data Traffic

On the Windows `vm-app`, use **RunPowerShellScript**:

```powershell
$Uri = "http://10.30.30.4:1433/"

Write-Output "Testing Application to Data..."
Write-Output "Destination: $Uri"

curl.exe `
    --max-time 5 `
    --fail `
    --show-error `
    $Uri

if ($LASTEXITCODE -eq 0) {
    Write-Output "PASS: Application-to-Data traffic is allowed."
}
else {
    Write-Output "FAIL: Application-to-Data traffic did not succeed."
}
```

Expected result:

```text
Data Tier
PASS: Application-to-Data traffic is allowed.
```

## 6. Test the Denied Web-to-Data Flow

On `vm-web`, run:

```powershell
$Uri = "http://10.30.30.4:1433/"

Write-Output "Testing the denied Web-to-Data flow..."
Write-Output "Destination: $Uri"

curl.exe `
    --max-time 5 `
    --show-error `
    $Uri

if ($LASTEXITCODE -ne 0) {
    Write-Output "PASS: Direct Web-to-Data traffic was blocked."
}
else {
    Write-Output "FAIL: Web-to-Data traffic was unexpectedly allowed."
}
```

Expected result:

```text
curl: connection timeout or failure
PASS: Direct Web-to-Data traffic was blocked.
```

A timeout is expected because the NVA uses a `DROP` rule rather than sending an explicit rejection.

## 7. Review NVA Firewall Counters

On `vm-nva`, open:

```text
Operations → Run command → RunShellScript
```

Run:

```bash
echo "Forwarding rules and packet counters:"

sudo iptables \
    -L FORWARD \
    -n \
    -v \
    --line-numbers
```

The packet counters should increase for:

* Web-to-application TCP `8443`
* Application-to-data TCP `1433`
* `ESTABLISHED,RELATED` return traffic
* Web-to-data logging
* Web-to-data dropping

To show only the most relevant rules:

```bash
sudo iptables -L FORWARD -n -v --line-numbers |
    grep -E '8443|1433|NVA_DROP_WEB_DATA|ESTABLISHED'
```

## 8. Review the Denied-Traffic Logs

After running the denied web-to-data test, execute on `vm-nva`:

```bash
sudo journalctl \
    -k \
    --since "30 minutes ago" |
    grep "NVA_DROP_WEB_DATA"
```

A log entry should include values similar to:

```text
NVA_DROP_WEB_DATA
SRC=10.30.10.4
DST=10.30.30.4
PROTO=TCP
DPT=1433
```

The exact formatting may differ.

To follow new kernel log entries:

```bash
sudo journalctl -k -f
```

Stop the live output with `Ctrl+C` when using an interactive terminal.

## 9. Capture Packets on the NVA

Packet capture provides additional evidence that the NVA receives both allowed and denied flows.

On `vm-nva`, start a short capture:

```bash
sudo timeout 30 tcpdump \
    -ni any \
    -nn \
    '((host 10.30.10.4 and host 10.30.20.4 and tcp port 8443) or
      (host 10.30.20.4 and host 10.30.30.4 and tcp port 1433) or
      (host 10.30.10.4 and host 10.30.30.4 and tcp port 1433))'
```

While the capture is running, repeat the connectivity tests from `vm-web` and `vm-app`.

For allowed traffic, the capture should show packets in both directions.

For the denied web-to-data flow, the capture should show connection attempts arriving at the NVA without a successful completed HTTP connection.

If using Azure Run Command, open the NVA command in one browser tab and run the workload tests from separate browser tabs.

## 10. Optional Azure Network Watcher Packet Capture

Azure Network Watcher can also create a capture session against an Azure VM.

In Network Watcher:

1. Select **Packet capture**.
2. Select **Add**.
3. Choose `vm-nva` as the target.
4. Configure a short capture duration.
5. Add filters for the relevant private IP addresses and ports.
6. Start the capture.
7. Run the workload connectivity tests.
8. Stop and download the capture.
9. Examine the file with a packet-analysis application.

The Network Watcher extension may need to be installed on the target VM.

Do not commit raw capture files containing sensitive traffic unless they have been reviewed.

## 11. Optional Internet Test

Because the workload route tables include `0.0.0.0/0`, internet-bound traffic should also use the NVA.

On `vm-web`, run:

```powershell
curl.exe `
    --head `
    --max-time 10 `
    https://learn.microsoft.com/
```

A successful HTTP response indicates that:

* The default route points to the NVA.
* The NVA forwards outbound traffic.
* The NVA's NAT rule is working.
* The NVA has outbound connectivity.
* DNS resolution is functioning.

If the test fails, first verify east-west routing separately. Internet routing introduces additional dependencies.

## 12. Troubleshooting

### Next Hop shows `VirtualNetwork`

The workload traffic is bypassing the NVA.

Check:

* The correct `/24` route exists.
* The route table is associated with the correct subnet.
* The destination IP is correct.
* The route is active.

### Next Hop shows `VirtualAppliance`, but allowed traffic fails

Check:

* Azure NIC IP forwarding on `vm-nva`
* `net.ipv4.ip_forward`
* NVA firewall rule order
* The destination service
* The destination operating-system firewall
* Network Security Group rules
* Return-path routes

### Web-to-data traffic succeeds

Check the NVA rule order:

```bash
sudo iptables -L FORWARD -n -v --line-numbers
```

The web-to-data `LOG` and `DROP` rules must appear before broad rules that could allow the traffic.

### Allowed traffic works in only one direction

Check the route table on the destination subnet.

For web-to-application traffic, verify:

```text
rt-web: 10.30.20.0/24 → 10.30.5.4
rt-app: 10.30.10.0/24 → 10.30.5.4
```

For application-to-data traffic, verify:

```text
rt-app:  10.30.30.0/24 → 10.30.5.4
rt-data: 10.30.20.0/24 → 10.30.5.4
```

### The NVA logs show no denied packets

Check:

* Next Hop from `vm-web` to `10.30.30.4`
* The `rt-web` association
* The NVA logging rule
* The logging rule's packet counter
* Whether the test used the correct destination IP and port

## 13. Validation Results

Complete this table after testing:

| Test                          | Expected result | Actual result | Status |
| ----------------------------- | --------------- | ------------- | ------ |
| Web → Application TCP `8443`  | Allowed         |               |        |
| Application → Data TCP `1433` | Allowed         |               |        |
| Web → Data TCP `1433`         | Denied          |               |        |
| Web → Application next hop    | `10.30.5.4`     |               |        |
| Application → Web next hop    | `10.30.5.4`     |               |        |
| Application → Data next hop   | `10.30.5.4`     |               |        |
| Data → Application next hop   | `10.30.5.4`     |               |        |
| NVA denied-traffic log        | Present         |               |        |
| NVA firewall counters         | Increased       |               |        |

## Expected Result

The completed validation should demonstrate:

```text
vm-web
   │
   │ TCP 8443 — Allowed
   ▼
vm-nva — 10.30.5.4
   │
   ▼
vm-app

vm-app
   │
   │ TCP 1433 — Allowed
   ▼
vm-nva — 10.30.5.4
   │
   ▼
vm-data

vm-web
   │
   │ Direct data access — Denied and logged
   ▼
vm-nva — DROP
```

The forward and return paths for approved connections should both use the NVA.
