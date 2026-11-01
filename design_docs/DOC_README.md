# Wgpu-weld documentation

Rust policy (2026-10-13): working toolchain 1.99.1 (`rust-toolchain.toml`) and shared MSRV 1.97.1, qualified separately. Canonical policy: `mere/design_docs/2026-08-12_family_composition_thesis_brief.md`, section "Shared Rust toolchain and minimum version".

This is the canonical index for active documentation in this repository.

## Working principles

- Keep CEF and platform facts separate from hardware receipts. State the
  platform, path, and measurement before calling a capability verified.
- Headed Linux preflights verify current runner-owned active Wayland sessions;
  never retain a logind session number as a durable hardware identity.
- Preserve identity across asynchronous producer boundaries. A bounded queue
  may reject admission, but it must not silently discard an accepted result.
- Keep browser policy in the host. Welding owns CEF adaptation and
  wgpu-importable frames, not an application's navigation or storage policy.
- Treat `README.md` as current public guidance and update it with any public
  contract change.
- Publish and tag the exact source being described. A public API change after
  publication receives a new crate version rather than reusing the old one.

## Active documents

- [Documentation policy](DOC_POLICY.md): shared documentation rules and the
  Wgpu-weld local addendum.
- [Producer gates plan](2026-11-01_producer_gates_plan.md): the open,
  deferred and follow-on work from the two archived plans: local gate
  mechanism including MSRV, CEF 154 Linux and Metal hardware parity, RADV
  native session-preflight acceptance, Wayland-native, auth, pen, the
  page-to-host bridge, printing, and the unimplemented host surfaces.

## Archive

[`archive_docs/2026-11-01/`](archive_docs/2026-11-01/) holds the two plans the
active plan was cut from, archived whole on 2026-11-01 with corrections marked
"Archive note": the
[CEF accelerated OSR plan](archive_docs/2026-11-01/2026-05-14_cef_accelerated_osr_plan.md)
(windowless rendering and GPU-import implementation record, all four phases
complete) and the
[producer parity plan](archive_docs/2026-11-01/2026-08-10_producer_parity_plan.md)
(cross-lane capability matrix and the W1-W10 evidence record). Receipts for the
active plan go to `archive_docs/receipts/2026-11-01_producer_gates_plan_receipts.md`.

## Maintainer-owned description

[PROJECT_DESCRIPTION.md](PROJECT_DESCRIPTION.md) is the maintainer-owned
project description required by the documentation policy. It has not yet been
created, so the root [README](../README.md) remains the public project
description until the maintainer supplies it.
