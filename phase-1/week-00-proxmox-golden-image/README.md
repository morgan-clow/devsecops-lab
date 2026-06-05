# Week 0 — Proxmox Golden Image & Mass Provisioning

## Goal
Build a standardized “golden image” in Proxmox and use Terraform to clone it into multiple VMs.

## What to learn
- Golden image → template → clone pattern
- Basic Terraform with the Proxmox provider
- How Terraform talks to the Proxmox API to create VMs

## Labs
- Create baseline CentOS Stream VM in Proxmox (updates, SSH keys, cloud-init)
- Convert that VM into a Proxmox template
- Write minimal Terraform config to clone the template
- Use Terraform to create 3–5 clones and verify SSH access

## Purpose & Expected Outcomes
By the end of Week 0:
- I have a reusable Proxmox template representing my standard Linux server
- I can use Terraform to programmatically create multiple VMs from that template
- I can explain how this pattern scales to 100+ servers

