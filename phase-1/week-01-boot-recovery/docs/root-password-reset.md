# Root Password Reset Procedure

## When to use this
- Root password is unknown or forgotten
- Security incident requiring immediate password change
- System inherited with no credentials

## Prerequisites
- Physical or console access to the server
- Ability to interrupt GRUB at boot

## Procedure

### Step 1 — Interrupt GRUB
- Reboot the server
- Press any key when GRUB menu appears
- Select first kernel entry
- Press 'e' to edit

### Step 2 — Add rd.break
- Find the line starting with 'linux'
- Navigate to end of line
- Add: rd.break
- Press Ctrl+X to boot

### Step 3 — Remount /sysroot
- Verify read-only: mount | grep sysroot
- Remount read-write: mount -o remount,rw /sysroot
- Verify read-write: mount | grep sysroot

### Step 4 — Change password
- Enter real filesystem: chroot /sysroot
- Change password: passwd root
- Confirm success message

### Step 5 — Fix SELinux and reboot
- touch /.autorelabel
- exit (leave chroot)
- exit (reboot system)
- Wait for SELinux relabeling on boot

### Step 6 — Verify
- Log in with new password
- Confirm access restored

## Important Notes
- Always touch /.autorelabel after changing files
  in initramfs — skipping this breaks SELinux login
- Boot will be slower than normal due to relabeling
- This procedure requires console access —
  cannot be done remotely
