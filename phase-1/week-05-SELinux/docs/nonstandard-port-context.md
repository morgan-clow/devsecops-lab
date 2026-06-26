# Lab 2 — Non-Standard Port Context

## Goal

Run Apache on a non-default port, observe the SELinux denial this causes, and fix it using semanage port — proving SELinux labels network ports the same way it labels files.

## Concept

httpd_t is only permitted to bind to ports specifically labeled http_port_t. Any port not in that list, even if completely unused and available, gets blocked by SELinux when an application tries to bind to it. This is the same scontext + tcontext + action model from file contexts, just applied to tcp_socket objects instead of file objects.

## Baseline

Command:
semanage port -l | grep http_port_t

Output:
http_port_t tcp 80, 81, 443, 488, 8008, 8009, 8443, 9000

Confirmed which ports were already allowed before making any changes. Port 8585 was not in this list.

## The Break

Commands:
sed -i 's/Listen 80/Listen 8585/' /etc/httpd/conf/httpd.conf
systemctl restart httpd
systemctl status httpd

Result:
Active: failed (Result: exit-code)
(13)Permission denied: AH00072: make_sock: could not bind to address 0.0.0.0:8585
no listening sockets available, shutting down

The specific wording "Permission denied" (rather than "address already in use") was the first clue this was a permissions-style block rather than a real network conflict.

## Diagnosis

Command:
ausearch -m avc -ts recent | tail -20

Output:
avc: denied { name_bind } for pid=17867 comm="httpd" src=8585
scontext=system_u:system_r:httpd_t:s0
tcontext=system_u:object_r:unreserved_port_t:s0
tclass=tcp_socket permissive=0

Read in plain English: Apache (httpd_t) tried to bind to port 8585, which is labeled unreserved_port_t — the generic default label for any port nobody has specifically claimed. Since http_port_t is the only port type httpd_t is allowed to bind to, this combination was denied. permissive=0 confirms enforcing mode was active.

## The Fix

Commands:
semanage port -a -t http_port_t -p tcp 8585
semanage port -l | grep http_port_t

Output:
http_port_t tcp 8585, 80, 81, 443, 488, 8008, 8009, 8443, 9000

Port 8585 is now part of the http_port_t policy. Restarted Apache:

systemctl restart httpd
systemctl status httpd

Result:
Active: active (running)
Server configured, listening on: port 8585

## Verification

Command:
curl http://localhost:8585/

Result: returned the default Apache/CentOS welcome page successfully — confirming the service is reachable and responding correctly.

Command:
ausearch -m avc -ts recent

Output:
<no matches>

Confirmed zero new denials after the fix.

## Key Lessons

1. SELinux labels network ports the same way it labels files — every port has a type, and processes can only bind to ports whose type matches what their policy allows
2. "Permission denied" when binding to an unused, available port is a strong signal of an SELinux block rather than a genuine network conflict (which would typically say "address already in use" instead)
3. semanage port -a -t type -p protocol port is the correct fix — adding the new port to the allowed type, not disabling SELinux or using audit2allow to create a broad exception
4. The same scontext/tcontext/action diagnostic model from file contexts (Lab 1) applies directly to network resources — only the object class (tcp_socket vs file) differs

## Commands Reference

Command: semanage port -l
Purpose: List all current port type assignments

Command: semanage port -l | grep http_port_t
Purpose: Check ports allowed for a specific type

Command: semanage port -a -t type -p protocol port
Purpose: Add a new port to an allowed type

Command: ausearch -m avc -ts recent
Purpose: View recent AVC denials (works for ports same as files)
