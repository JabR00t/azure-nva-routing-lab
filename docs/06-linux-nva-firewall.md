# Configure the Linux NVA Firewall

## Purpose

This stage configures the Linux Network Virtual Appliance to inspect, allow, deny, log, and forward traffic.

The NVA implements the following policy:

| Source                  | Destination            |       Port | Action         |
| ----------------------- | ---------------------- | ---------: | -------------- |
| Web subnet              | Application subnet     | TCP `8443` | Allow          |
| Application subnet      | Data subnet            | TCP `1433` | Allow          |
| Web subnet              | Data subnet            |        Any | Deny and log   |
| Workload subnets        | Internet               |        Any | Allow with NAT |
| Other east-west traffic | Other workload subnets |        Any | Deny           |

## Network Definitions

| Network                | Address range   |
| ---------------------- | --------------- |
| Entire virtual network | `10.30.0.0/16`  |
| Web subnet             | `10.30.10.0/24` |
| Application subnet     | `10.30.20.0/24` |
| Data subnet            | `10.30.30.0/24` |
| NVA private address    | `10.30.5.4`     |

## Configuration Script

The firewall configuration is stored in:

```text
scripts/linux/configure-nva-firewall.sh
```

The script performs the following actions:

1. Enables Linux IPv4 forwarding.
2. Installs persistent iptables support.
3. Sets the default forwarding policy to `DROP`.
4. Drops invalid packets.
5. Allows response traffic for approved connections.
6. Allows web-to-application traffic on TCP `8443`.
7. Allows application-to-data traffic on TCP `1433`.
8. Logs and denies direct web-to-data communication.
9. Denies other unapproved east-west traffic.
10. Allows internet-bound workload traffic.
11. Applies source NAT to internet-bound traffic.
12. Saves the configuration.

## Run the Script

In Azure Portal, open:

```text
vm-nva → Operations → Run command → RunShellScript
```

Paste and run the contents of:

```text
scripts/linux/configure-nva-firewall.sh
```

## Rule Order

Firewall rule order is important.

The response-traffic rule is evaluated before the rules that allow new connections:

```text
ESTABLISHED,RELATED → ACCEPT
```

This allows response packets from the application and data tiers after the original connection has been approved.

The web-to-data logging rule appears immediately before the web-to-data drop rule:

```text
Web → Data → LOG
Web → Data → DROP
```

The `LOG` action records the packet but does not stop rule processing. The following `DROP` rule blocks it.

## Validation

Check Linux forwarding:

```bash
sysctl net.ipv4.ip_forward
```

Expected output:

```text
net.ipv4.ip_forward = 1
```

Display forwarding rules:

```bash
sudo iptables -L FORWARD -n -v --line-numbers
```

Display NAT rules:

```bash
sudo iptables -t nat -L POSTROUTING -n -v --line-numbers
```

Display the saved configuration:

```bash
sudo iptables-save
```

## View Denied-Traffic Logs

After attempting a direct connection from `vm-web` to `vm-data`, run:

```bash
sudo journalctl -k --since "15 minutes ago" |
    grep "NVA_DROP_WEB_DATA"
```

The rule includes rate limiting to prevent repeated denied packets from creating excessive log entries.

## Important Testing Note

The NVA will not receive workload traffic until the user-defined route tables are associated with the workload subnets.

At this stage, Azure may continue routing traffic directly between the workload subnets.

The route tables will be configured in the next stage.

## Expected Result

At the end of this stage:

```text
vm-nva — 10.30.5.4
├── Linux IP forwarding enabled
├── Stateful return traffic allowed
├── Web → Application TCP 8443 allowed
├── Application → Data TCP 1433 allowed
├── Web → Data denied and logged
├── Other unapproved east-west traffic denied
└── Internet-bound traffic NATed
```
