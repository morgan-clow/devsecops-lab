# Lab 4 — Automated SELinux Relabel Playbook

## Goal

Automate the manual SELinux context-fixing workflow from Labs 1-3 (create directory, set persistent policy, apply restorecon) using an idempotent Ansible playbook, instead of running each command by hand every time.

## Concept

Everything done manually this week (semanage fcontext, restorecon, ausearch verification) needs to be repeatable and automated for real production use across many servers. This playbook captures that exact workflow as code.

## The Playbook

File: selinux-relabel.yml

---
- name: Ensure correct SELinux context for custom web content
  hosts: localhost
  become: true
  vars:
    web_dir: /webcontent
    web_context_type: httpd_sys_content_t
  tasks:
    - name: Ensure the directory exists
      ansible.builtin.file:
        path: "{{ web_dir }}"
        state: directory
        mode: "0755"

    - name: Set persistent SELinux fcontext policy for the directory
      community.general.sefcontext:
        target: "{{ web_dir }}(/.*)?"
        setype: "{{ web_context_type }}"
        state: present

    - name: Apply the SELinux context to existing files
      ansible.builtin.command:
        cmd: "restorecon -Rv {{ web_dir }}"
      register: restorecon_result
      changed_when: "'Relabeled' in restorecon_result.stdout"

    - name: Show what restorecon actually changed
      ansible.builtin.debug:
        var: restorecon_result.stdout_lines

## Key Module Notes

community.general.sefcontext is the Ansible module equivalent of semanage fcontext -a — it adds the persistent policy rule the proper Ansible way, with built-in idempotency (safe to run repeatedly without creating duplicate rules or errors).

changed_when: "'Relabeled' in restorecon_result.stdout" overrides Ansible's default behavior of always marking a command task as "changed." This makes the playbook only report a real change when restorecon's actual output contains the word "Relabeled" — meaning something genuinely needed fixing. If everything was already correct, the task correctly reports no change.

## Execution

Command:
ansible-playbook selinux-relabel.yml

Result: all tasks completed successfully. The debug task confirmed the actual fix:

"Relabeled /webcontent from unconfined_u:object_r:default_t:s0 to unconfined_u:object_r:httpd_sys_content_t:s0"

## Verification

Command:
ls -laZ /webcontent/

Result: both the directory and index.html correctly labeled httpd_sys_content_t — matching the same fix performed manually throughout Labs 1-3, now fully automated.

## Mistake and Fix Encountered

Initially attempted to add a task creating /webcontent/index.html using a malformed path expression:

path: "{{ web_dir }}" / "{{ web_file }}"

This caused a YAML parsing error, since two separately-quoted strings cannot be concatenated with a bare slash between them. Corrected to a single quoted string containing both variables and a literal slash:

path: "{{ web_dir }}/{{ web_file }}"

This task was ultimately removed from the final playbook, since serving the file over HTTP required additional Apache Alias configuration outside the scope of this lab — the goal here is automating the SELinux context fix, not building a working website.

## Key Lessons

1. community.general.sefcontext and the restorecon command task together replicate the exact manual workflow from Labs 1-3, as idempotent, repeatable code
2. changed_when with a string-matching condition lets a playbook accurately report whether a real fix occurred, rather than always claiming "changed" by default
3. Jinja2 variables must be combined within a single quoted string ("{{ a }}/{{ b }}") rather than concatenated across separate quoted strings
4. Running the same playbook with hosts: localhost on a different machine than originally intended still produces a correct result — proving the logic itself is portable, even if the target machine needs to be deliberately chosen for a real deployment

## Commands Reference

Command: ansible-playbook playbook.yml
Purpose: Execute a playbook against the hosts defined within it

Command: ansible-galaxy collection list | grep community.general
Purpose: Verify a required Ansible collection is installed

Command: community.general.sefcontext (module)
Purpose: Ansible equivalent of semanage fcontext -a, idempotent
