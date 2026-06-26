# Week 5 — SELinux

## Overview

This week covers SELinux troubleshooting in enforcing mode — reading AVC denials, fixing file and port contexts correctly, understanding the durability of policy rules versus manual overrides, and automating the entire workflow with Ansible. All labs performed on phase1-vm-1 (CentOS Stream 9) in a Proxmox homelab, with Lab 4's playbook also run on manage-node to test portability.

## Core Concept — Reading an AVC Denial

Every AVC denial answers three questions:

WHO tried to do it -> scontext (source/process type)
WHAT were they trying to do TO -> tcontext (target/resource type)
WHAT action -> the permission requested (getattr, name_bind, etc)

SELinux checks whether the combination of scontext + tcontext + action is explicitly allowed by policy. This is completely independent of standard Linux file permissions — both systems must allow an action for it to succeed. permissive=0 in a denial confirms enforcing mode was active when the block happened.

## Core Concept — Two Categories of Context Problems

Category 1, custom or unknown paths: the base SELinux policy has no built-in opinion about what the correct label should be. New content defaults to the generic default_t. restorecon alone does nothing useful here — a semanage fcontext rule must be added first to teach policy what the correct type is, then restorecon applies it.

Category 2, standard well-known paths that get manually corrupted: the base policy already has a built-in correct answer (for example /var/www/html is already known to be httpd_sys_content_t). restorecon alone is sufficient to fix corruption here, with no semanage fcontext needed.

## Core Concept — chcon vs semanage fcontext

chcon makes an immediate, one-time, non-persistent change directly to a file's label. It never touches the policy database. semanage fcontext -a writes a permanent rule into the policy database itself. Once that rule exists, restorecon can be run any number of times in the future to undo manual corruption (from chcon, package updates, or full relabels) without ever needing to repeat the semanage step. This was proven directly: corrupting /webcontent with chcon and running restorecon alone fixed it instantly, using the policy rule already established in Lab 1.

## Core Concept — audit2why and audit2allow Are Easy to Misuse

audit2why correctly explains that a denial was caused by a missing type enforcement rule, and suggests audit2allow can generate a module to allow the access. This is often the WRONG fix. It creates a broad policy exception granting the process access to the entire mismatched type system-wide, rather than fixing the actual mislabeled resource. The correct fix is almost always relabeling the resource to its proper type, not expanding what the process is allowed to touch.

## Labs Completed

Lab 1, Apache File Context Mismatch: deployed content in a non-standard directory, observed a real 403 and the AVC denial behind it, recognized audit2allow's suggestion was the wrong fix, and corrected it with semanage fcontext plus restorecon.

Lab 2, Non-Standard Port Context: moved Apache to a non-default port, observed the bind failure and its AVC denial (name_bind against unreserved_port_t), and fixed it with semanage port.

Lab 3, Context Corruption and Restoration: corrupted both a standard system path and a custom path with an existing policy rule, proving restorecon's behavior depends entirely on whether a correct policy answer already exists for that path.

Lab 4, Automated Relabel Playbook: built an idempotent Ansible playbook using community.general.sefcontext and a changed_when-guarded restorecon task, automating the manual workflow from Labs 1-3.

## Real-World Incident Patterns Demonstrated

A 403 or bind failure with permissions-style wording despite correct application-level config (Require all granted, no port conflict) is the signature of an SELinux block, not an application misconfiguration.

"It was working yesterday" inconsistencies, like a directory and its parent showing different contexts, are the signature of manual context corruption on a previously-correct path.

A quick, lazy audit2allow fix can silently widen a process's access far beyond what was intended, trading a clear, narrow problem for a much broader, harder-to-notice security gap.

Automating the fix as a playbook makes the correct remediation repeatable across a fleet, rather than relying on someone remembering the right manual sequence under pressure.

## Commands Reference

Command: sestatus
Purpose: Full SELinux status, mode, and policy type

Command: ls -laZ path
Purpose: View SELinux context alongside file permissions

Command: ausearch -m avc -ts recent
Purpose: View recent AVC denials

Command: ausearch -m avc -ts recent piped to audit2why
Purpose: Human-readable explanation of a denial, use with caution

Command: semanage fcontext -a -t type "path(/.*)?"
Purpose: Add a persistent file context policy rule

Command: semanage port -a -t type -p protocol port
Purpose: Add a port to an allowed SELinux port type

Command: restorecon -Rv path
Purpose: Apply policy's correct context to real files on disk, recursively, with output

Command: chcon -t type path
Purpose: Temporary, non-persistent manual label change, easily overwritten by restorecon

Command: community.general.sefcontext (Ansible module)
Purpose: Idempotent equivalent of semanage fcontext -a, for automation
