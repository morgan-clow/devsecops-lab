# Lab 1 — Apache File Context Mismatch and AVC Denial

## Goal

Deploy web content in a non-standard location, observe a real SELinux AVC denial, correctly diagnose it using ausearch and audit2why, and fix it properly — without ever disabling or setting SELinux to permissive.

## Concept — Reading an AVC Denial

Every AVC denial answers three questions:

WHO tried to do it? -> scontext (source/process type)
WHAT were they trying to do TO? -> tcontext (target/resource type)
WHAT action? -> the permission requested

SELinux checks whether the combination of scontext + tcontext + action is explicitly allowed by policy. This is completely independent of standard Linux file permissions (chmod/chown) — both systems must allow an action for it to succeed.

## Baseline

Command:
sestatus

Output:
Current mode: enforcing
Loaded policy name: targeted

Confirmed SELinux active and enforcing before starting.

Command:
systemctl status httpd

Apache installed and running cleanly on port 80.

## The Break — Wrong Context by Default

Commands:
mkdir /webcontent
echo "<h1>Test Page</h1>" > /webcontent/index.html
ls -laZ /webcontent

Output:
unconfined_u:object_r:default_t:s0  index.html

New content outside any directory SELinux specifically knows about inherits the generic default_t type — not the type Apache is permitted to read.

Created an Apache alias pointing at this directory:

Alias /test /webcontent
<Directory /webcontent>
    Require all granted
</Directory>

Command:
curl http://localhost/test/index.html

Result: 403 Forbidden — despite Require all granted in the Apache config itself (proving this is not an Apache permissions problem).

## Diagnosis

Command:
ausearch -m avc -ts recent

Output:
avc: denied { getattr } for pid=... comm="httpd"
path="/webcontent/index.html"
scontext=system_u:system_r:httpd_t:s0
tcontext=unconfined_u:object_r:default_t:s0
tclass=file permissive=0

Read in plain English: Apache (running as httpd_t) tried to getattr (read file attributes) on a file labeled default_t — not a type Apache is allowed to touch. permissive=0 confirms this denial happened while SELinux was actively enforcing, not just logging.

Command:
ausearch -m avc -ts recent | audit2why

Output:
Was caused by:
    Missing type enforcement (TE) allow rule.
    You can use audit2allow to generate a loadable
    module to allow this access.

Important lesson: audit2why's suggestion (audit2allow) is technically valid but the WRONG fix here. It would create a policy exception allowing httpd_t to access ANY default_t file system-wide — a much broader and riskier change than necessary. The correct fix is changing the file's label to the correct type, not granting Apache permission to touch the wrong label everywhere.

## The Correct Fix

Identified the correct target context from Apache's known-working default directory:

Command:
ls -laZ /var/www/html/

Output:
system_u:object_r:httpd_sys_content_t:s0

Applied the fix in two distinct steps:

Commands:
semanage fcontext -a -t httpd_sys_content_t "/webcontent(/.*)?"
restorecon -Rv /webcontent

Output:
Relabeled /webcontent from default_t to httpd_sys_content_t
Relabeled /webcontent/index.html from default_t to httpd_sys_content_t

semanage fcontext alone only updates what the label should be going forward — it does not retroactively relabel existing files. restorecon is what actually applies the change to files already on disk.

## Verification

Command:
curl http://localhost/test/index.html

Output:
<h1>Test Page</h1>

Content now serves correctly.

Command:
ausearch -m avc -ts recent

Output:
<no matches>

Confirmed zero new denials since the fix — a clean, complete resolution.

## Key Lessons

1. New content outside SELinux-known directories defaults to default_t, not the type the serving application expects
2. ausearch -m avc -ts recent is the first command to run when suspecting an SELinux-related failure
3. audit2why/audit2allow are easy to misuse — they often suggest a working-but-overly-broad fix (granting access to the wrong label) instead of the correct, narrow fix (relabeling the resource)
4. semanage fcontext -a sets policy; restorecon applies it — both steps are required, in that order
5. SELinux denials are completely independent of standard file permissions — Require all granted in Apache config did nothing to prevent this denial

## Commands Reference

| Command | Purpose |
|---|---|
| sestatus | Full SELinux status (mode, policy type) |
| ls -laZ path | View SELinux context alongside file permissions |
| ausearch -m avc -ts recent | View recent AVC denials |
| ausearch -m avc -ts recent piped to audit2why | Human-readable explanation of a denial |
| semanage fcontext -a -t type "path(/.*)?" | Add a persistent file context policy rule |
| restorecon -Rv path | Apply context policy to real files on disk |
