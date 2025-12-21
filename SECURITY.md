# Security Policy

## 🛡️ Reporting Security Issues

The Tejas Linux project takes security issues seriously.

If you believe you have found a **security vulnerability** in Tejas Linux, please **do not open a public GitHub issue**.

Instead, report it responsibly using one of the methods below.

---

## 📬 How to Report

### Preferred method

Send a detailed report via **email** to:

```
tejas.linux@vaibhavpandey.com
```

Please include:

- A clear description of the vulnerability
- Steps to reproduce (if applicable)
- Affected versions / editions (User / Developer)
- Any relevant logs, screenshots, or proof-of-concept code

---

### Optional: Encrypted reports (recommended)

You may encrypt your report using the **Tejas Linux GPG release key**.

#### 🔑 GPG key details

- **Key ID:** `A3F982C55AD5DA0B`
- **Key type:** RSA 4096

The public key is available in this repository:

```
tejas-linux-public.key
```

Or from Ubuntu keyservers:

```bash
gpg --keyserver keyserver.ubuntu.com --recv-keys A3F982C55AD5DA0B
```

To encrypt your report:

```bash
gpg --encrypt --armor -r A3F982C55AD5DA0B report.txt
```

---

## ⏱️ Response Timeline

We aim to:

- **Acknowledge** receipt within **72 hours**
- **Assess and validate** the issue as quickly as possible
- **Coordinate a fix** and release timeline responsibly

Critical vulnerabilities may result in **out-of-band releases**.

---

## 🔐 Supported Versions

Security updates apply to:

- The **latest stable release** of Tejas Linux
- Actively developed pre-release versions (if applicable)

Older releases may not receive fixes unless the issue is critical.

---

## 🔏 Release Integrity & Trust Model

Tejas Linux uses a **CI-based, cryptographically verifiable release process**:

- ISOs are built in **GitHub Actions**
- Artifacts are signed using the **Tejas Linux GPG release key**
- SHA256 checksums are published alongside releases
- Users are encouraged to verify **both signature and checksum**

Refer to `README.md` for detailed verification instructions.

---

## 🧩 Secure Boot & Third-Party Software

- Tejas Linux uses **Ubuntu’s Secure Boot chain**
  - Microsoft-signed shim
  - Canonical-signed GRUB
  - Canonical-signed kernel

- Proprietary or DKMS-based drivers (e.g. NVIDIA) may require **MOK enrollment**
  - This behavior is expected and documented

Security issues related solely to **upstream Ubuntu packages** should generally be reported upstream as well.

---

## 🚫 Scope Exclusions

The following are **out of scope** for security reports:

- Issues in unsupported or heavily modified systems
- Vulnerabilities introduced by third-party software installed by users
- Denial-of-service caused by intentional misuse
- Social engineering attacks

If unsure, **report anyway** — we will triage responsibly.

---

## 🧠 Responsible Disclosure

We ask that reporters:

- Avoid public disclosure until a fix is available
- Give reasonable time for investigation and remediation
- Coordinate disclosure if the issue affects upstream Ubuntu or third parties

We are committed to **responsible, transparent handling** of security issues.

---

## 🙏 Acknowledgements

We appreciate the efforts of security researchers and community members who help keep Tejas Linux safe.

Contributors who responsibly disclose security issues may be acknowledged in release notes (with consent).

---

**Thank you for helping keep Tejas Linux secure.**
