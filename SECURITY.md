# Security Policy — Tejas Linux

This document describes the security model, trust chain, and vulnerability
reporting process for **Tejas Linux**.

---

## 🔐 Trust & Release Integrity

Tejas Linux publishes **cryptographically verifiable releases**.

Each official ISO release includes:

- A **SHA256 checksum** (`.sha256`)
- A **detached GPG signature** (`.sig`)
- A **signed Secure Boot chain** (amd64)

Users are strongly encouraged to verify downloads before installation.

---

## 🔑 GPG Release Signing

All official Tejas Linux releases are signed with the **Tejas Linux Release Key**.

### Verification steps

```bash
gpg --import tejas-linux-public.key
gpg --verify tejas-linux.iso.sig tejas-linux.iso
sha256sum -c tejas-linux.iso.sha256
```

Only releases that pass **both** GPG verification and checksum validation
should be trusted.

---

## 🔐 Secure Boot (amd64)

Tejas Linux supports **UEFI Secure Boot on amd64 systems**.

The Secure Boot chain is:

```
UEFI firmware
 → shim (Microsoft-signed)
 → GRUB (signed)
 → Linux kernel (signed)
```

No unsigned bootloaders or kernels are shipped in official amd64 ISOs.

---

## 🔧 Secure Boot & Third-Party Drivers (DKMS)

When Secure Boot is enabled:

- Proprietary or out-of-tree drivers (e.g. NVIDIA, Broadcom Wi-Fi)
  are built locally using **DKMS**
- These modules are signed using a **Machine Owner Key (MOK)**
- Users may be prompted once to enroll a key during reboot

This behavior is **expected and required** for Secure Boot compatibility.

Tejas Linux does **not** bypass Secure Boot, disable kernel lockdown,
or auto-enroll keys without user consent.

---

## 🧩 Supported Architectures

| Architecture   | Status                  |
| -------------- | ----------------------- |
| amd64 (x86_64) | Fully supported         |
| arm64          | Not currently supported |

Security guarantees apply only to **officially supported architectures**.

---

## 🚨 Reporting Security Issues

If you discover a security vulnerability in:

- Tejas build scripts
- Installer configuration
- Boot process
- Release infrastructure

Please report it **privately**.

### 📧 Contact

Email:

```
tejas.linux@vaibhavpandey.com
```

(or open a private GitHub security advisory if enabled)

Please **do not open public issues** for security vulnerabilities.

---

## ⏱️ Response Policy

- Acknowledgement: **within 72 hours**
- Initial assessment: **within 7 days**
- Fix & disclosure: coordinated based on severity

Critical issues affecting release integrity or boot security
are prioritized.

---

## 🔍 Scope

This security policy applies to:

- Tejas Linux build system
- Official ISO images
- Release signing process
- Secure Boot configuration

It does **not** cover:

- Upstream Ubuntu package vulnerabilities
- Third-party software bugs
- Hardware firmware issues

Upstream vulnerabilities should be reported to the appropriate project.

---

## 📜 Responsible Disclosure

Tejas Linux follows responsible disclosure practices.

We appreciate researchers who:

- Provide clear reproduction steps
- Allow time for fixes
- Avoid public disclosure before mitigation

---

## 🛡️ Disclaimer

Tejas Linux is provided **as-is**, without warranty.
Security guarantees apply only to official releases
built and signed by the Tejas Linux project.

---

Last updated: 2025-12-21
