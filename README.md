# Phase 1 — Linux Foundations, Hardening & Compliance (Weeks 0–12)

This repository contains **Phase 1** of my 32‑week Platform Engineering project.

Phase 1 focuses on:

- Strong **RHEL/Linux fundamentals** (boot, storage, services, networking)
- **Security & compliance** (STIG, OpenSCAP, SELinux, auditd)
- **Hardening & automation** (Ansible, AWX)
- **Incident response** and documentation

All of this is built and tested in a **Proxmox home lab** to simulate a real environment with a 100+ server fleet.

---

## Goals of Phase 1

By the end of Phase 1 (Weeks 0–12), I will be able to:

- Design a standard Linux server build and provision many identical servers using Proxmox + Terraform.
- Recover broken systems (boot issues, storage issues, service failures, SELinux denials).
- Harden RHEL‑like systems to meet STIG‑style requirements.
- Run and interpret OpenSCAP compliance scans and remediate findings.
- Use Ansible (and later AWX) to apply hardening and configuration at scale.
- Investigate and document security incidents with proper evidence and timelines.

---

## Week Index (0–12)

Each week has its own folder under `phase-1/` with:

- A `README.md` describing **Goal**, **What to learn**, **Labs**, and **Purpose & Expected Outcomes**.
- Supporting files (scripts, playbooks, screenshots, notes).

> Links below will point to those folders as I create them.

| Week | Topic | Link |
|---|---|---|
| Week 0 | Proxmox Golden Image & Mass Provisioning | [Week-00](https://github.com/morgan-clow/devsecops-lab/tree/main/phase-1/week-00-proxmox-golden-image) |
| Week 1 | Boot Process & Recovery | [Week-01](https://github.com/morgan-clow/devsecops-lab/tree/main/phase-1/week-01-boot-recovery) |
| Week 2 | Storage Deep Dive (LVM, filesystems, disk‑full recovery) | (to be created) |
| Week 3 | systemd & Services (unit files, dependencies, troubleshooting) | (to be created) |
| Week 4 | Networking Fundamentals (ip, DNS, routing, firewalld, tcpdump) | (to be created) |
| Week 5 | SELinux (AVC denials, semanage, booleans, ports) | (to be created) |
| Week 6 | Logging & Audit (rsyslog, auditd, chrony, central logging) | (to be created) |
| Week 7 | DISA STIG Study (controls, CKL, POA&M mapping) | (to be created) |
| Week 8 | OpenSCAP (scanning, remediation, rescanning) | (to be created) |
| Week 9 | Account & SSH Hardening (PAM, sshd, sudo) | (to be created) |
| Week 10 | Ansible Hardening Roles | (to be created) |
| Week 11 | AWX & Incident Response Simulation | (to be created) |
| Week 12 | Phase 1 Stress Test & Review | (to be created) |

---
