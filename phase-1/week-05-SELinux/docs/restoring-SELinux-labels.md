# Lab 3 — Restoring SELinux Labels After Context Corruption

## Goal

Simulate SELinux context corruption on both a standard system path and a custom path with an existing policy rule, and prove the different mechanisms restorecon relies on in each case.

## Concept

restorecon does not track history or "recent changes." It compares a file's current label against what the POLICY DATABASE says it should be, and fixes any mismatch. There are two distinct sources that database can pull from:

1. Built-in defaults shipped with the base SELinux policy, for well-known standard paths (like /var/www/html)
2. Custom rules added manually with semanage fcontext, for paths the base policy has never heard of

Whether restorecon alone is sufficient to fix a corrupted label depends entirely on which category the path falls into.

## Test 1 — Standard System Path (/var/www/html)

Baseline, confirmed correct before testing:

Command:
ls -laZ /var/www/html/

Output:
system_u:object_r:httpd_sys_content_t:s0

Corrupted it manually:

Command:
chcon -t default_t /var/www/html
ls -laZ /var/www/html/

Result: directory itself (.) changed to default_t, while its parent (..) remained httpd_sys_content_t — an inconsistency exactly like what a real "it was working yesterday" incident looks like.

Ran restorecon with no other steps:

Command:
restorecon -Rv /var/www/html

Output:
Relabeled /var/www/html from default_t to httpd_sys_content_t

restorecon alone was sufficient. /var/www/html is a well-known standard Apache path with a built-in rule already present in the base SELinux policy — no semanage fcontext was needed because the correct answer already existed before this directory was ever corrupted.

## Test 2 — Custom Path With an Existing Policy Rule (/webcontent)

Recall from Lab 1: a semanage fcontext rule for /webcontent was already added permanently to policy, setting it to httpd_sys_content_t.

Corrupted both the directory and the file inside it:

Command:
chcon -t default_t /webcontent/
chcon -t default_t /webcontent/index.html
ls -laZ /webcontent/

Result: both directory and file showed default_t.

Ran restorecon:

Command:
restorecon -Rv /webcontent/

Output:
Relabeled /webcontent from default_t to httpd_sys_content_t
Relabeled /webcontent/index.html from default_t to httpd_sys_content_t

restorecon alone fixed both, with zero need to run semanage fcontext again. The persistent policy rule added once in Lab 1 is durable — it survives any number of future chcon corruptions, package updates, or relabels.

## Key Lessons

1. restorecon does not track history — it always compares current labels against the policy database's correct answer and fixes mismatches
2. For standard, well-known system paths, the base SELinux policy already has a built-in correct answer — restorecon alone is sufficient, no semanage fcontext required
3. For custom application paths the base policy has never seen, restorecon has no correct answer to apply until a semanage fcontext rule is added first (this was the Lab 1 scenario)
4. Once a semanage fcontext rule exists for a path, it is permanent and durable — restorecon can be run any number of times afterward to undo manual corruption, with no need to repeat the semanage step
5. chcon makes an immediate, one-time, non-persistent change directly to a file's label — it never touches the underlying policy database, which is exactly why its changes are so easily and automatically overwritten by restorecon

## Commands Reference

Command: chcon -t type path
Purpose: Manually and temporarily set a label directly on a file or directory (does not update policy)

Command: restorecon -Rv path
Purpose: Compare current labels against policy and fix mismatches, recursively, with verbose output

Command: ls -laZ path
Purpose: View current SELinux context alongside file permissions

Command: ausearch -m avc -ts recent
Purpose: Confirm whether a context mismatch actually triggered a real denial
