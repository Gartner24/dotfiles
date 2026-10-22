# 0007. System files: rationale

Decision record for [index.md](index.md).

## Context

0001 AC-7 built the system copy path (diff against the live file, ask, `sudo install` root owned) and threaded it with keyd. The scope row for feature 9 lists keyd, earlyoom, the pacman hook, the K70 fix and your user systemd units. The read only checks of 2026-10-14 are in index.md *Probes*. The K70 fix lives in `~/.local/share/k70-core-fix/` (memory `k70-core-fix`): C source, a shared header, 21 tests, build and rollback scripts, a README, the support ticket draft, and `upstream/` (the merged MR's notes). The object installed in `/etc/udev-hid-bpf/` is compiled against the running kernel's type info (`vmlinux.h` from `/sys/kernel/btf/vmlinux`).

## Options considered

### Option 1: source as a stow package, build on the machine on request (chosen)
- Pros: no binary in git; the tests travel with the code; one yes per new machine.
- Cons: needs `clang` and `bpftool` on the desktop (both installed today).

### Option 2: copy the compiled object as a system file
- Pros: no build step.
- Cons: a 1 MB binary built for one kernel; wrong on the next kernel; unreviewable diff.

### Option 3: leave the K70 fix out
- Pros: nothing to build.
- Cons: the keyboard types nothing on a new install until you find the folder in a backup.

## Rationale

System files that are plain text stay on 0001's copy path. The K70 object is generated, so the repo keeps what generates it. The offer is gated on the keyboard being present so a machine without it never sees the question.

## Decided without asking (2026-10-14)

1. **earlyoom config.** Options: track `/etc/default/earlyoom`; track nothing and enable the service. Picked: nothing; the file is the stock one (P1). The service goes in feature 10's service list.
2. **K70 fix form.** Options: compiled object as a system file; source package built on request; leave out. Picked: source package (Option 1).
3. **K70 package profile.** Options: desktop with an `hw:` comment; a separate hardware profile. Picked: desktop with the comment; the offer is gated on the device, so a third profile buys nothing.
4. **When to offer the build.** Options: always ask on desktop; ask only with the device present and the object missing; never ask (README only). Picked: device present and object missing.
5. **What of the K70 folder is tracked.** Options: everything; source, tests, scripts and README only. Picked: source, tests, scripts, README. The ticket holds a product SKU and is unsent (personal); `upstream/` is the history of a merged MR.
6. **`99-corsair-hid.rules` (firmware tool access).** Options: track as a system file; leave out. Picked: track, as `system/corsair-hid/`; it is yours and small. Not `system/k70-core-fix/`: `dot` resolves a profile name to `home/<n>` before `system/<n>` (`load_profile`), so one name cannot be both a package and a system folder.
7. **Other udev rules** (Innioasis, MediaTek, USB Blaster, Panda wifi). Options: track all; leave out. Picked: leave out; their device tools' installers wrote them and will again. Pull one in by adding it under `system/`.
8. **User systemd units.** Options: a new `systemd-desktop` package; put the Ghostty override in `home/ghostty`. Picked: `home/ghostty`; the override exists only for Ghostty and goes away with it. claude-config's units stay with claude-config (0002).
9. **Pacman hook.** Moved by feature 8 (spec 0006 AC-6), listed here only so the table is complete.
10. **Test seams.** Options: test the K70 check only on the real machine; env overrides for `/sys` and `/etc/udev-hid-bpf`. Picked: overrides, read only by the K70 check, so the logic is tested without the keyboard.
