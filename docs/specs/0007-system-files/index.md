# 0007. System files: keyd and the pacman hook as copies, the K70 fix as source built on the machine, a Ghostty unit override

**Date**: 2026-10-14
**Status**: Proposed
**Paths:** `dot`, `system/**`, `home/k70-core-fix/**`, `home/ghostty/**`, `profiles/desktop`, `deny.list`, `.gitignore`, `tests/dot-status.sh`
**Builds on**: [0001](../0001-repo-layout-linking/index.md) AC-7 (the system copy path, already built). Feature 9.

## Summary

The scope row names five things: `/etc/keyd` (the arrow key fix), `/etc/default/earlyoom`, the pacman hook, the Corsair K70 HID-BPF fix (a small program loaded into the kernel's input layer that makes the keyboard type at all and filters its chattering switches) and your user systemd units (service files systemd runs for your user). Checked on 2026-10-14: keyd is already a system folder; `/etc/default/earlyoom` is the package's own file, unmodified (`pacman -Qii`: `[unmodified]`), so there is nothing to track, only the service to enable; the pacman hook moves with feature 8 (spec 0006 AC-6); of the user units, two belong to claude-config (spec 0002) and one is yours, the Ghostty override. The K70 fix is different from the rest: what sits in `/etc/udev-hid-bpf/` is a compiled object built against this kernel, so the repo tracks its source and scripts, and the machine builds and installs it.

## What you're agreeing to

- keyd and the pacman hook stay plain copies into `/etc`, shown as a diff and written with sudo only after you say yes (as today).
- earlyoom's config file is not tracked (it is the stock file); the bootstrap enables its service (feature 10).
- The K70 fix's source, tests and scripts move into the repo (desktop only); its compiled file never does. `dot install` offers to build and install it only when that keyboard is plugged in and the fix is missing.
- Your Ghostty systemd override goes into the Ghostty package; the claude-config units stay with claude-config.
- Your support ticket draft and the upstream merge request notes stay out of the repo.

Context, options and rationale: [rationale.md](rationale.md).

## Requirements

**User stories**:
- As the owner, I want the arrow key fix and the K70 keyboard working on a new install of this hardware, with every system change shown before it happens.
- As the owner of a public repo, I want no compiled kernel object and no support ticket committed.

**Acceptance criteria**:
- **AC-1** (keyd, unchanged): `system/keyd/etc/keyd/default.conf` stays as built by 0001.
- **AC-2** (earlyoom): no `system/earlyoom/`. Feature 10's service list enables `earlyoom` (spec 0008 AC-6).
- **AC-3** (K70 package): `home/k70-core-fix/.local/share/k70-core-fix/` holds `0010-Corsair__K70-CORE.bpf.c`, `KNOWN-GOOD-rdesc-only.bpf.c`, `k70_debounce_core.h`, `hid_bpf.h`, `hid_bpf_helpers.h`, `hid_report_descriptor_helpers.h`, `test_debounce.c`, `run-tests.sh`, `rebuild.sh`, `rollback.sh`, `restore-debounce.sh`, `README`. It is listed in `profiles/desktop` under a `# hw: Corsair K70 CORE` comment. `.gitignore` ignores `*.bpf.o` and `vmlinux.h` there. `CORSAIR_SUPPORT_TICKET.md` and `upstream/` are not tracked, and `deny.list` gains the path pattern `^([^ ="']*/)?CORSAIR_SUPPORT_TICKET\.md$`.
- **AC-4** (K70 build): `rebuild.sh` builds both objects (`0010-Corsair__K70-CORE.bpf.o` and `KNOWN-GOOD-rdesc-only.bpf.o`) before installing the first, so `rollback.sh` works on a fresh clone.
- **AC-5** (K70 offer): during `dot install desktop`, when a HID device `0003:1B1C:1BFD.*` exists under `/sys/bus/hid/devices/` and `/etc/udev-hid-bpf/0010-Corsair__K70-CORE.bpf.o` does not, install prints `k70: keyboard found, fix not installed` and asks `build and install the K70 fix (sudo)?`; yes runs `~/.local/share/k70-core-fix/run-tests.sh` then `rebuild.sh`. With `-n` or no terminal it only prints the line. Without the device it prints nothing. `dot status` reports `k70: keyboard found, fix not installed` as a problem under the same condition.
- **AC-6** (`99-corsair-hid.rules`): `system/corsair-hid/etc/udev/rules.d/99-corsair-hid.rules` (the rule that lets Corsair's browser firmware tool reach the keyboard), listed in `profiles/desktop` next to the package, installed through 0001 AC-7. The generated `99-hid-bpf-0010-Corsair__K70-CORE.rules` is not tracked (`udev-hid-bpf install` writes it).
- **AC-7** (Ghostty override): `home/ghostty/.config/systemd/user/app-com.mitchellh.ghostty.service.d/override.conf`, linked by stow like any package file; `systemctl --user cat app-com.mitchellh.ghostty.service` shows it after `systemctl --user daemon-reload`.
- **AC-8** (no state): `git ls-files` shows no `*.bpf.o`, no `vmlinux.h`, no ticket, and nothing under `system/` for `/etc/sudoers.d` (0001), counted by a check in `tests/dot-status.sh` that walks `git ls-files` and prints the count of violations, which must be 0.
- **AC-9** (tests): `tests/dot-status.sh` covers AC-5 with a fake `/sys` root (`DOT_SYSFS` overriding `/sys`, `DOT_HIDBPF_DIR` overriding `/etc/udev-hid-bpf`, both read only by the K70 check): device plus no object prints the line and status counts a problem; device plus object prints nothing; no device prints nothing.

## Feature design

**What goes where**:

| Item | Repo path | Live path | How |
|---|---|---|---|
| keyd | `system/keyd/etc/keyd/default.conf` | `/etc/keyd/default.conf` | copy, diff, sudo (0001) |
| pacman hook | `system/real-app-icons/etc/pacman.d/hooks/real-app-icons.hook` | same under `/` | copy (spec 0006 AC-6) |
| Corsair firmware tool rule | `system/corsair-hid/etc/udev/rules.d/99-corsair-hid.rules` | same under `/` | copy |
| K70 fix source | `home/k70-core-fix/.local/share/k70-core-fix/*` | `~/.local/share/k70-core-fix/*` | stow link |
| K70 compiled fix | not tracked | `/etc/udev-hid-bpf/0010-Corsair__K70-CORE.bpf.o` | `rebuild.sh` (sudo inside `udev-hid-bpf install`) |
| earlyoom | not tracked (stock file) | `/etc/default/earlyoom` | service enabled by feature 10 |
| Ghostty override | `home/ghostty/.config/systemd/user/app-com.mitchellh.ghostty.service.d/override.conf` | same under `~` | stow link |
| claude-config units | not here | `~/.config/systemd/user/{claude-ram-watch,hookgate-review}.*` | claude-config installer (0002) |

**Value sourcing**:

| Action | Value | Source |
|---|---|---|
| install | K70 present | `/sys/bus/hid/devices/0003:1B1C:1BFD.*` exists (vendor and product id from the README and the live udev rule) |
| install | K70 fix installed | `/etc/udev-hid-bpf/0010-Corsair__K70-CORE.bpf.o` exists |
| install | which system folders | `profiles/desktop` names (0001 AC-7) |
| tests | fake roots | `DOT_SYSFS`, `DOT_HIDBPF_DIR` env vars, test only |

**Key invariants**:
- No compiled object or generated header in git.
- `dot` itself never runs sudo for the K70 fix; `rebuild.sh` does, after you say yes.
- Unchanged from 0001: system files are copies, never links.

**Security model**: the K70 build runs `clang` and `udev-hid-bpf install` with sudo, only on yes. The repo is public; the fix code is already public upstream in part (MR !251), the debounce half is yours. The ticket (product SKU) stays out by `deny.list`.

**Critical test scenarios**:
- Fake sysfs cases. Verifies **AC-5**, **AC-9**.
- `git ls-files` walk, count 0. Verifies **AC-8**.
- `run-tests.sh` passes from the linked folder (21 checks). Verifies **AC-3**.
- On this desktop: `dot install desktop -n` shows no K70 line (fix installed) and the diffs for any changed system file. Verifies **AC-5**, **AC-6**.
- On the real keyboard after a kernel update: you run `rebuild.sh`, replug, `sudo bpftool prog show | grep k70_core_debounce`. Verifies **AC-4**.

## Build plan

1. `git mv`-style move of the K70 sources into `home/k70-core-fix/` (copy from `~/.local/share/k70-core-fix/`, leave the ticket and `upstream/`), ignore rules, `deny.list` line, `profiles/desktop` entry; `dot install desktop` backs up the real files and links them. Satisfies **AC-3**.
2. `rebuild.sh` builds both objects. Satisfies **AC-4**.
3. K70 check in `dot install` and `dot status` with the two env overrides, and its tests. Satisfies **AC-5**, **AC-9**.
4. `system/corsair-hid/` with the firmware tool rule, listed in `profiles/desktop`. Satisfies **AC-6**.
5. Ghostty override into `home/ghostty/`, relink, `daemon-reload`, `systemctl --user cat`. Satisfies **AC-7**.
6. `git ls-files` violation count in `tests/dot-status.sh`. Satisfies **AC-8**.
7. You check on the hardware: arrow key fix, K70 types without doubles, earlyoom active (after feature 10). Waits on you.

## Probes

| Probe | Command | Result |
|---|---|---|
| P1 earlyoom config is stock | `pacman -Qii earlyoom` | ran 2026-10-14: `/etc/default/earlyoom [unmodified]` |
| P2 services enabled today | `systemctl is-enabled earlyoom keyd docker bluetooth sddm` | ran 2026-10-14: all `enabled` |
| P3 rules on disk | `ls /etc/udev/rules.d /etc/udev-hid-bpf` | ran 2026-10-14: the K70 object, the generated rule, `99-corsair-hid.rules`, plus device tool rules (see rationale) |
| P4 systemd follows a linked drop-in | after step 5: `systemctl --user cat app-com.mitchellh.ghostty.service` | shows `Type=dbus` (build runs it; read only) |
| P5 K70 build from a clone | `rebuild.sh` on the real keyboard | you, needs sudo |

## Consequences

**Positive**:
- The K70 fix survives a reinstall and its tests run from the repo.
- Every `/etc` change is still a diff you approve.

**Negative / tradeoffs**:
- A kernel update can still need `rebuild.sh` by hand (unchanged from today).
- Device tool rules for Innioasis, MediaTek, USB Blaster and the Panda wifi stick are not tracked; their own installers write them.

**Neutral**:
- `home/ghostty` gains a systemd file; the override comment already says when to remove it.

## Follow-up

- [ ] Feature 10: enable `earlyoom`, `keyd`, `docker`, `bluetooth` (spec 0008 AC-6).
- [ ] When Ghostty ships the `SIGUSR2` fix, delete the override (its own comment).
