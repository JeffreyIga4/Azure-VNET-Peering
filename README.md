# Azure Hub-and-Spoke VNet Peering with Bastion (Terraform)

This project provisions a **secure hub-and-spoke network architecture in Azure** using Terraform.  
The goal was to enable **private, internal-only connectivity** between virtual machines while enforcing proper network security controls and avoiding public exposure.

All infrastructure is deployed via Terraform and validated through real network tests (ping and SSH).

---

## What Was Built

### Core Components

- **Shared (Hub) Virtual Network**
  - Hosts Azure Bastion
  - Acts as the secure access point
- **Test (Spoke) Virtual Network**
  - Hosts Linux virtual machines
  - No public IPs
- **Azure Bastion**
  - Secure browser-based SSH access
- **VNet Peering**
  - Bidirectional peering between hub and spoke
- **Network Security Groups (NSGs)**
  - SSH allowed only from the Shared VNet
  - Default deny for all other inbound traffic

---

## Architecture Overview
```yaml
Internet
|
Azure Portal
|
Azure Bastion
|
Shared VNet (10.0.0.0/16)
|
VNet Peering
|
Test VNet (10.1.0.0/16)
|
Linux VMs (Private IPs only)
```

---

## Network Design

### Address Space

| Component | CIDR |
|---------|------|
| Shared VNet | `10.0.0.0/16` |
| Azure Bastion Subnet | `10.0.0.0/26` |
| Shared Subnet | `10.0.1.0/24` |
| Test VNet | `10.1.0.0/16` |
| Test Subnet | `10.1.0.0/24` |

> The Bastion subnet is **explicitly reserved** and named `AzureBastionSubnet` as required by Azure.

---

## Security Model

- No public IPs on virtual machines
- Bastion used for initial access
- SSH restricted via NSG rules
- No internet exposure to VMs

### NSG Rule Summary

- **Inbound**
  - Allow TCP 22 **only from Shared VNet CIDR**
  - Deny all other inbound traffic
- **Outbound**
  - Default Azure outbound rules

---

## Deployment Steps

```bash
terraform init
terraform plan
terraform apply
```

---

## Connectivity Testing

All connectivity tests were performed **after Terraform deployment** to validate VNet peering, NSG rules, and private communication between virtual machines.

---

### Test 1 — Azure Bastion → VM

**Goal:**  
Verify secure administrative access without public IPs.

**Steps:**
- Open Azure Bastion in the Azure Portal
- Connect to VM using SSH
- Authenticate as `azureuser`

**Result:**  
SSH session established successfully via Bastion.


![9CEAC232-852D-4EE4-831C-B4F0E6300BFA_1_201_a](https://github.com/user-attachments/assets/a6ea0983-2733-4bb2-8362-98a46258c09d)

---

### Test 2 — VM1 → VM2 (Private IP)

**Goal:**  
Confirm east–west traffic is allowed within the Test VNet.

**Commands run on VM1:**

```bash
ping -c 4 <VM2_PRIVATE_IP>
nc -zv <VM2_PRIVATE_IP> 22
```

![0F8659D2-7023-4BC6-8CC8-047F2C7EB32E_1_201_a](https://github.com/user-attachments/assets/b63b5e81-ce0c-499f-a0fa-51e858096be2)

---

### Test 3 — VM2 → VM1 (Private IP)

**Goal:**  
Validate bidirectional communication across the VNet.

**Commands run on VM2:**

```bash
ping -c 4 <VM1_PRIVATE_IP>
nc -zv <VM1_PRIVATE_IP> 22
```


![CE1C6B85-CA0D-4BD9-930D-AFBFF3AAFADA_1_201_a](https://github.com/user-attachments/assets/edd8d9bf-264d-45e9-bd3e-3100ca4c9dc9)


---

### Challenges Faced (And How They Were Solved)

#### 1. Bastion Disconnecting Immediately

**Issue:**  
Bastion SSH sessions disconnected as soon as the session loaded.

**Root Cause:**  
Network Security Group (NSG) rules were blocking inbound traffic on port 22.

**Fix:**  
Created an inbound NSG rule allowing SSH (port 22) **from the Shared VNet CIDR**, with a higher priority than the default deny rules.

---

#### 2. Subnet CIDR Overlap Errors

**Issue:**  
Terraform failed during apply with subnet overlap errors.

**Root Cause:**  
The Azure Bastion subnet CIDR overlapped with an existing subnet in the Shared VNet.

**Fix:**  
Reserved a dedicated `/26` CIDR block specifically for `AzureBastionSubnet`, as required by Azure.

---

