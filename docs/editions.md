# Public and private editions

## Public edition

The public edition is the output of this repository. It changes only what the board
needs to boot and expose its hardware correctly. It must retain standard Armbian
presentation and defaults wherever those defaults do not prevent the hardware from
working.

Public output must not contain:

- custom banners, logos, hostnames, usernames, passwords, or SSH keys;
- saved Wi-Fi networks, regulatory settings inferred from one owner, or Bluetooth
  pairings;
- Tailscale installation state, enrollment, node identity, or access policy;
- display rotation, console font, or another owner-specific screen choice (the
  public hardware profile does force the validated 720p compatibility mode and
  documents a 1080p alternative); or
- device dumps, factory firmware, eMMC backups, logs, serial numbers, or identifiers.

## Private edition

An owner may maintain a separate local overlay for presentation, networking,
display, and administration preferences. That overlay consumes a pinned public
release; it does not fork or duplicate the underlying board-support files.

The private overlay must be excluded from public Git history and release archives.
Secrets still do not belong in it: credentials should be entered through trusted
local prompts or dedicated restricted files, never embedded in scripts.

## Release test

Build the public image in a clean directory using only cloned public sources and
documented downloads. Inspect its mounted filesystems and first-boot behavior. If an
owner-specific string or setting appears, the public release fails.
