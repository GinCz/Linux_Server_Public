# ☁️ Oracle Cloud Always Free — Complete Infrastructure Guide & 0.00 € / Month Hardening

> **Status:** Always Free Tier (Lifetime Free, 0.00 € / $0.00 per month)  
> **Repository:** [GitHub: Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)  
> **Official Documentation:** [Oracle Cloud Free Tier Overview ↗](https://www.oracle.com/cloud/free/)

---

## 1. Validity: 1 Year or Lifetime Free?

Oracle Cloud operates on a **two-tier model**:

1. **30-Day Free Trial:**
   - **$300 (or ~250 €)** in cloud credits upon sign-up.
   - Can be used for any paid service, high-end compute shapes, enterprise databases, and licensed Windows Server images during the first 30 days.
   - Expired credits are forfeit after 30 days without penalty.
2. **Always Free (Lifetime):**
   - Services marked with the **`Always Free Eligible`** badge remain **100% free forever**, not just for 1 year (unlike AWS and Azure, which limit free tiers to 12 months).
   - Monthly cost is strictly **0.00 € / month** when staying within the allocated quotas.

---

## 2. Complete Always Free Service Catalog

### 🖥️ 1. Compute Instances (Up to 6 VMs Simultaneously)
* **ARM Ampere A1 Flex (`VM.Standard.A1.Flex`):**
  * **4 OCPUs** (Ampere Altra ARM Neoverse N1 physical cores) and **24 GB RAM** total per tenancy.
  * Monthly allocation: **3,000 OCPU-hours** and **18,000 GB-hours** (equivalent to running 4 OCPUs and 24 GB RAM continuously in **24/7/365** mode).
  * Flexible allocation across **1 to 4 VMs**:
    * 1 High-Performance instance: `4 OCPU / 24 GB RAM` (Databases, Docker stacks, heavy workloads);
    * 2 Balanced instances: `1 OCPU / 2 GB RAM` (VPN/proxy gateway) + `3 OCPU / 22 GB RAM` (Main server / Windows ARM);
    * 4 Micro nodes: `1 OCPU / 6 GB RAM` each.
* **AMD EPYC Micro (`VM.Standard.E2.1.Micro`):**
  * **2 Micro VMs** on x86_64 architecture (`1/8 OCPU` AMD, `1 GB RAM` each).
* **Total Instances:** You can run **up to 6 virtual machines** simultaneously (4 ARM + 2 AMD) at zero cost.

### 💾 2. Storage & Backup Quotas
* **Boot & Block Volumes:** Total **200 GB** NVMe storage across all instances.
* **Volume Backups:** Up to **5 free volume backups**.
* **Object Storage (S3-compatible):**
  * **10 GB** Standard Object Storage (hot tier).
  * **10 GB** Archive Storage (cold tier).
  * Up to **50,000 API requests** per month.

### 🌐 3. Networking, Traffic & IP Addresses
* **Public IPv4:** **Up to 2 Public IPv4 addresses free** (Ephemeral or Reserved Static).
* **IPv6:** Free **/64** subnet allocated to each Virtual Cloud Network (VCN).
* **Outbound Data Transfer (Egress):** **10 TB (10,000 GB) per month** worldwide free.
* **Inbound Data Transfer (Ingress):** **100% unlimited and free**.
* **Virtual Cloud Networks (VCN):** Up to 2 VCNs with subnets, route tables, security lists, Internet Gateways, NAT Gateways, and Service Gateways.
* **Load Balancers:**
  * 1 **Flexible Load Balancer** (L7) capped at **10 Mbps** bandwidth.
  * 1 **Network Load Balancer** (L4).

### 🗄️ 4. Managed Autonomous Databases
* **2 Autonomous Databases:** Choice of **Autonomous Transaction Processing (ATP)** or **Autonomous Data Warehouse (ADW)**.
* **Resources per Database:** `1 OCPU` and `20 GB storage` each (total 2 OCPU and 40 GB storage).
* **Oracle APEX:** Built-in low-code development environment.
* **Database Actions:** Full-featured SQL Developer Web console.

### 🛠️ 5. Developer Tools & Security
* **OCI Container Registry (OCIR):** Up to **500 MB** for private Docker/OCI container image storage.
* **Resource Manager:** Managed Terraform (IaC) execution engine with unlimited runs.
* **OCI Vault (KMS):** Up to **20 master encryption keys** and secret management.
* **Bastion Service:** Up to **5 concurrent secure bastion sessions** for private subnet access.

### 📊 6. Observability & Management
* **OCI Monitoring:** Performance metrics collection (up to 500 million ingestion points/month).
* **OCI Logging:** Up to **10 GB log ingestion per month** free.
* **OCI Notifications:** Up to **1 million webhook deliveries** and **1,000 email alerts** per month.

---

## 3. Step-by-Step 0.00 € / Month Hardening Guide

Follow these rules to ensure your Oracle Cloud account never incurs unexpected charges:

### Step 1: Create a Financial Budget Alert
1. In the OCI Console, navigate to: **Governance & Administration** ➔ **Billing & Cost Management** ➔ **Budgets**.
2. Click **Create Budget**:
   - **Scope:** `Root Compartment` (entire tenancy).
   - **Monthly Budget Amount:** `1.00` (1 USD / 1 EUR).
   - **Day of Month to Process:** `1`.
3. Add an **Alert Rule**:
   - Trigger at `100% of Actual Spend` and `100% of Forecast Spend`.
   - Set **Recipients Email** to your active mailbox.
> *Result:* You will receive an instant email if any service generates even $0.01 in charges.

---

### Step 2: Compute Instance Configuration
1. Always look for the green **`Always Free Eligible`** badge next to the selected shape.
2. Select **Ampere** (`VM.Standard.A1.Flex`) and ensure:
   - Total OCPUs across all ARM VMs ≤ **4**.
   - Total RAM across all ARM VMs ≤ **24 GB**.
3. Choose standard Linux images (**Ubuntu 24.04 ARM**, **Debian 12 ARM**, or **Oracle Linux**).  
   *Do NOT choose standard Windows Server images from the marketplace, as Microsoft licensing fees apply.*

---

### Step 3: Boot Volume & Performance Configuration
1. In the **Boot Volume** section, click **Specify a custom boot volume size**.
2. Enter the exact size (e.g., `50 GB` for VPN node, `150 GB` for Main node). Ensure the sum of all boot and block volumes does not exceed **200 GB**.
3. **Volume Performance:** Set slider strictly to **Balanced (10 VPU/GB)**.  
   *Do not select Higher Performance (20 VPU) or Ultra High Performance, as VPU > 10 is billed separately.*

---

### Step 4: IP Allocation & Load Balancer Limits
1. Check **Assign a public IPv4 address** on **at most 2 instances**.
2. For additional instances, uncheck public IPv4 and use free **IPv6** or access via the **Bastion Service** / private VCN subnet.
3. For Load Balancers, select **Flexible Load Balancer** with a fixed **10 Mbps** bandwidth limit (or Network Load Balancer).

---

### Step 5: Autonomous Database Configuration
1. When creating an Autonomous Database, ensure the **`Always Free`** toggle switch is enabled.
2. This locks the database to 1 OCPU / 20 GB and disables OCPU Auto Scaling.

---

### Step 6: Disable Heavy Oracle Cloud Agent
Oracle Cloud telemetry agents consume up to 300–500 MB of RAM by default.
1. During instance creation, under **Oracle Cloud Agent**, uncheck:
   - `Compute Instance Monitoring`
   - `OS Management Hub`
   - `Vulnerability Scanning`
2. Or run on an active Linux server:
   ```bash
   sudo systemctl stop snap.oracle-cloud-agent.oracle-cloud-agent
   sudo systemctl disable snap.oracle-cloud-agent.oracle-cloud-agent
   ```

---

### Step 7: Protect Against Idle Instance Reclamation
Oracle automatically reclaims Always Free instances on free accounts if 7-day 95th-percentile metrics show:
- CPU utilization < 20%
- Memory utilization < 20%
- Network utilization < 20%

#### Method A: Lightweight Keep-Alive Daemon (`lookbusy`)
```bash
sudo apt update && sudo apt install -y build-essential
lookbusy -c 22 -m 1500MB
```

#### Method B (The Golden Standard): Upgrade to Pay-As-You-Go (PAYG)
- Navigate to **Billing & Cost Management** ➔ **Upgrade to Paid (Pay-As-You-Go)**.
- A temporary authorization hold of ~$100 (or ~93 €) is placed on your credit card for 15–30 minutes and released immediately.
- **Benefits:**
  1. **Always Free resources on PAYG accounts are exempt from idle instance reclamation.**
  2. High host allocation priority in busy regions (eliminates `Out of host capacity` errors).
  3. **Monthly bill remains strictly 0.00 €** as long as you stay within Always Free quotas.

---

## 4. Deploying 350 MB Mini-Linux (DietPi) on Oracle Cloud

You can install an ultra-fast, minimal Linux distribution (**DietPi**, ~350 MB image, < 50 MB idle RAM) on any Oracle Cloud instance using our automated in-RAM live installer.

* **Full Guide:** [`DIETPI_INSTALLATION_GUIDE.md` ↗](DIETPI_INSTALLATION_GUIDE.md)
* **Installer Script:** [`dietpi_installer.sh` ↗](dietpi_installer.sh)

```bash
# One-liner execution on a fresh Debian 12 instance:
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Oracle_Cloud/dietpi_installer.sh | bash
```

---

## 5. Summary Quotas & Settings Checklist

| Resource | Always Free Quota | Hardening Rule |
|---|---|---|
| **ARM CPU & RAM** | 4 OCPU / 24 GB RAM | Sum across all ARM VMs ≤ 4 OCPU / 24 GB |
| **AMD CPU & RAM** | 2 Micro VMs (1/8 OCPU / 1 GB) | Shape: `VM.Standard.E2.1.Micro` |
| **Storage** | 200 GB NVMe | Sum of volumes ≤ 200 GB, VPU = 10 (Balanced) |
| **Public IPv4** | 2 Addresses | Max 2 Public IPv4s assigned |
| **Egress Traffic** | 10 TB / month | Stay under 10,000 GB outbound |
| **Autonomous DB** | 2 DBs (2 OCPU / 40 GB) | `Always Free` switch enabled |
| **Load Balancer** | 1 Flexible LB (10 Mbps) + 1 NLB | Bandwidth fixed to 10 Mbps |
| **Cost Alert** | $1.00 / 1.00 € | Configured in `Budgets` with email alert |
| **Idle Protection** | PAYG Account | Upgrade to PAYG for zero-cost immunity |