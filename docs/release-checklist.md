# Release checklist

## Technical qualification

- [x] Exact PCB marking and date define the supported hardware boundary.
- [x] Finished image and checksum were generated from pinned inputs.
- [x] USB flash passed byte-for-byte verification.
- [x] UART helper cold boot passed on an untouched second unit.
- [x] Guarded eMMC installation and activation passed on the second unit.
- [x] USB-free eMMC cold boot passed.
- [x] Automatic USB recovery precedence passed without UART input.
- [x] Recovery-media overwrite guard passed a synthetic filesystem test.
- [x] Public image contains no owner branding or configured account/network state.

## Publication gates

- [ ] Beginner instructions pass from a fresh repository checkout.
- [x] Public audit passes on the current source tree.
- [x] Firmware and image redistribution terms are documented.
- [ ] Repository contains no disk images, firmware blobs, backups, credentials, private
  paths, raw logs, serial numbers, or network identifiers.
- [ ] Release image and matching checksum are uploaded as immutable assets.
- [ ] The release notes identify known limitations and the exact PCB date.
- [ ] A source tag records the commit used for the release.

## Upstream handoff

- [x] Goldfinger-only board files are identified separately from generic changes.
- [x] Generic installer-hook changes and the proposed split are documented.
- [ ] Hardware evidence and UART logs are redacted.
- [ ] The ophub patch/PR links back to the standalone tested release.

Do not delay disclosure of known limitations merely to make the checklist look
complete. A first publication may be labeled experimental while the unchecked
hardware coverage items in `docs/status.md` remain explicit.

The current blocking item for binary-image upload is rebuilding with the proven
BCM4359C0 firmware and confirming one cold USB boot; see `docs/redistribution.md`.
