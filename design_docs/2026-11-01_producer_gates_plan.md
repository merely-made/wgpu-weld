# Producer gates plan: Weld's remaining gates and capability tail

**Status:** 2026-11-01: cut from `2026-08-10_producer_parity_plan.md` and
`2026-05-14_cef_accelerated_osr_plan.md`, both archived whole in
`archive_docs/2026-11-01/`. Landed there: the OSR plan's four phases (Windows,
macOS, Linux import on Intel/Mesa and, since `0b0dc5f`, AMD/RADV on wgpu 30);
parity phases W1-W10 (honest probe, popup widget surfaces, HiDPI, cursor and
IME, cookies, the renderer-side `CefApp`, downloads, permissions and context
menus, find, zoom, print to PDF, touch, drag, PNG snapshot, per-producer
profiles, CDP, the ordered `poll_web_event` stream and owned native frames);
the Windows sandbox bootstrap (`61c3c05`); `background_color`; `welding` 0.15.0
published 2026-10-17 on CEF 154 (`154.5.0+154.0.34`), with the Windows CEF 154
qualification (locked check, 60 library tests, sandboxed DX12 pixel smoke); the
Linux headed-preflight repair committed (`5327970`, 2026-10-05). The GitHub
workflows were removed 2026-10-28 (`a32955a`), so every run link in the archived
plans is historical and gates live in local scripts and dated receipts. Open:
the local gate mechanism including MSRV (P1), CEF 154 Linux and Metal hardware
parity (P2), RADV native preflight acceptance (P3), Wayland-native (P4, D1),
Linux import and renderer-death coverage (P5), wgpu-28 on hardware (P6), auth
(P7), input (P8), the page-to-host bridge and sync seam (P9), printing (P10),
the unimplemented host surfaces (P11) and hygiene (P12).

**For:** closing the distance between what `welding` implements and what has a
local, dated, per-platform receipt, so the public claim stays no wider than the
receipts, and finishing the capability tail the parity matrix still marks
partial or missing.

Not here:
- Turnstone consumer qualification of CEF 154 and Weld (coordinated consumer
  repin and host gates): owned in Turnstone,
  `turnstone/design_docs/2026-11-02_browser_surface_implementation_plan.md` and
  `turnstone/design_docs/2026-11-02_user_agent_taxonomy_plan.md`;
- published versions, package order, the Graft 0.7 / Scry 0.8 / Weld 0.15.1
  train (which also resolves `welding`'s `grafting` requirement, see Findings)
  and the registry-only four-host proof:
  `wgpu-graft/design_docs/2026-11-01_triplet_release_plan.md` (P2, P3);
- Scry's S2 (its matrix's unverified cells: win/mac IME observability, touch
  coverage, wk6 native input) and S4 (WebView2 CDP exposure): tracked in
  `wgpu-scry/docs/parity-matrix.md`, owned by wgpu-scry;
- Graft's G2 (explicit grafting feature selection; the adapter is now
  `grafting-servo`): owned by wgpu-graft;
- the neutral browser-surface contract and Mere's `welding-0-15` adapter:
  `mere/design_docs/inker_docs/research/2026-09-03_web_surface_contract_assessment.md`.

Receipts from this plan's runs go to
`archive_docs/receipts/2026-11-01_producer_gates_plan_receipts.md`, never into
this plan (DOC_POLICY section 8). Evidence that matters is a test in the
repository or a line in Findings.

**Keyword.** `producer_gates`: most of what remains is a gate (a receipt on a
named host, a local script that replaces a deleted workflow, or a probe flipped
together with its pin test), and each capability item below closes on the same
kind of evidence. `producer_parity` would describe the finished matrix, not the
remainder.

## Constraints

Carried from the archived plans and `DOC_README.md`:

- State the platform, path and measurement before calling a capability
  verified. A negative is evidence only with a positive control in the same run
  (a `LoadEnd` event, a known-good page, a frame count): three archived
  false negatives came from a demo's own instrument.
- `CefSurfaceCapabilities::probe` may not overstate. Every `Supported` is pinned
  by `probe_only_claims_what_is_wired` (`surface.rs:373`); a feature that lands
  flips its status and that test in one change.
- CEF's paint handles are callback-scoped: Weld takes ownership inside the
  callback (D3D11 copy on Windows, `CFRetain` on macOS, `dup(2)` on Linux) and
  exposes only owned resources. After handoff to Graft the host does not close
  the handle or fd.
- Any CEF C API parameter that the C++ API takes by reference must be non-null;
  null buys a silent no-op. UI-thread-only getters (`zoom_level`,
  `ExecuteDevToolsMethod`'s id) read wrong off the UI thread, so verify from the
  page.
- CEF's native DevTools window stays refused on all three producers; the CDP
  path is the supported inspector basis.
- Keep browser policy in the host. Weld owns CEF adaptation and
  wgpu-importable frames, not an application's navigation or storage policy.
- A bounded queue may reject admission but must not silently discard an
  accepted result; identity survives asynchronous producer boundaries.
- Headed Linux preflights verify the runner-owned active Wayland session; never
  retain a logind session number as a hardware identity.
- A public API change after publication receives a new crate version.
- Hardware gates are local scripts with dated receipts. No agent runs more than
  three tasks at a time (Mark, 2026-10-06); the machines are shared.

## Phases

### P1. Local gate mechanism after CI removal

`a32955a` deleted `hardware-headed.yml`, `hardware-parity.yml`, `msrv.yml`,
`rust-policy.yml` and `wgpu-matrix.yml`. What those ran has no replacement: the
MSRV lane (library compile on `rust-version` 1.97.1 with `-D warnings`, tests on
the `wgpu-28` row, plus a separate `cef-runtime` lane on three operating
systems), the nine-row OS by wgpu-version library matrix, the three CEF demo
builds, rustfmt and a manifest-policy check (first-party `rust-version`
declarations resolved on 1.97.1 and 1.99.1). `scripts/parity-battery.sh` survives
but its `WELD_SKIP_CASES` lists lived in the deleted workflows.

Done when each removed gate has a local command or script in `scripts/`, or a
recorded decision to drop it with the reason; MSRV's home is decided (Q1) and a
dated receipt shows the library compiling on 1.97.1 and testing green; and the
parity battery's documented per-host skips are written down beside the script.

### P2. CEF 154 Linux and Metal hardware parity

Only Windows has CEF 154 runtime receipts (2026-10-07). Linux and both Macs
last passed on CEF 151 or earlier; `README.md` says fresh CEF 154 Linux/Metal
runtime parity remains open.

Done when, on the Fedora ThinkPad (AMD Renoir / RADV), the M4 iMac (macOS 26,
arm64) and the Intel iMac (macOS 15.7): a fresh isolated build of the committed
source runs the sandboxed pixel fixture to its pixel verdict (readback on Metal;
the Linux verdict per P3), the parity battery reaches PASS or a named SKIP on
every case with no FAIL, and the macOS popup behaviour is recorded per
generation (full path on 26 / arm64, absent on 15.7 / Intel). Receipts name the
CEF build each host measured. After P3 for Linux.

### P3. RADV native session-preflight acceptance as a local-script gate

The 2026-10-05 repair (`5327970`) replaced a stale logind session-ID assertion
with discovery of the runner's active Wayland session
(`scripts/assert-active-wayland-session.sh`), and `scripts/test-active-wayland-session.sh`
covers rotated-ID admission and inactive, X11, other-user, no-session,
query-failure and missing-property refusals. Eight mocked cases passed under Git
Bash on Windows; it has not run on the ThinkPad.

Done when, on the ThinkPad in an active native Wayland session, the mocked test
passes natively, the preflight passes against the real session, and a CEF pixel
receipt passes immediately after it from a local script (not a workflow); and
the same preflight refuses when run from an inactive or X11 session on that
host (the positive control).

### P4. Wayland-native on Linux (D1)

`demo-weld-linux` runs through XWayland. Its module header
(`demo-weld-linux/src/main.rs:19`) says Wayland is not supported by the CEF
Linux DMABUF path, while `README.md:27`, `README.md:77` and `welding/README.md:79`
describe a RADV native-Wayland CI fixture. Per D1 the removed `radv-wayland`
jobs' parity passes are historical and the item is open.

Done when a local script launches `demo-weld-linux` natively on an active
Wayland session on RADV (preflight from P3 immediately before), and the receipt
names the windowing backend winit actually used and the ozone platform CEF's
Chromium used, with a positive control (the same script forced onto X11 reports
the other backend); the pixel fixture (`WELD_PIXEL_FIXTURE=1`,
`WELD_EXIT_AFTER_FRAMES`) reads back the expected pixels; Khronos validation
emits no VUID. Only then is the demo header corrected, and the three README
passages are made true to the receipts either way.

### P5. Linux import and renderer-death coverage

- **Linux popup re-measure.** Popup geometry was correct on RADV but the import
  was refused by the modifier block fixed in `0b0dc5f`. Done when the ThinkPad
  shows an `imported popup` receipt with real pixels from the `<select>` probe
  on wgpu 30, or a measured reason it does not.
- **`OnRenderProcessTerminated` on Linux.** Chromium logs `Failed to send
  GetTerminationStatus request to zygote` and the callback never fires;
  `--no-zygote` and a 70 s window did not change it. The CDP stream did show
  `Inspector.targetCrashed` on a terminated renderer (archived W9 note). Done
  when frames resume after a deliberate renderer crash on Linux (the frame-count
  metric is now available because RADV imports), through the callback, a CDP
  fallback or another mechanism, or the plan records why none exists. The crash
  case in the battery stops being skipped on RADV.
- **NVIDIA proprietary on Linux.** CEF issue 3687 reported DMABUF plus Vulkan
  not viable. Done when a receipt exists on an NVIDIA proprietary Linux host, or
  the claim is recorded as dropped because no host is available (Q8).
- **Disjoint multi-plane DMA-BUF and non-RGBA formats.** Graft returns
  `VulkanDisjointDmabufNotSupported`; Weld accepts only shared-buffer
  BGRA8/RGBA8. Done when a real CEF frame in such a layout is observed and
  handled (import or typed refusal with a test), or a run records that CEF 154
  never produces one on the verified GPUs.

### P6. wgpu-28 on hardware

The `wgpu-28` row compiles on all three hosts and is configuration-tested; no
one has run it on hardware, and `wgpu-29` retains live DX12 and Metal receipts
only. Done when a headed import receipt exists on each path for `wgpu-28`
(demos built against that row), or the README and crate docs say "compiles,
not exercised" in the place a consumer looks, with the row kept or dropped by
decision.

### P7. Auth challenges (W7b)

`GetAuthCredentials` is registered on all three producers with the whole answer
path (`answer_auth`, `cancel_auth`) behind it, and CEF has never been seen to
call it: a probe counted zero invocations against a top-level 401 that Chromium
failed with `ERR_INVALID_AUTH_CREDENTIALS`, with and without the Alloy runtime
style. That observation was on CEF 147; proxy auth was never tried. The probe
reports `Partial`, and its reason text still says CEF 147 (`surface.rs:317`).

Done when, on CEF 154, a probe records whether CEF calls the handler for server
auth and for a proxy challenge; then either an `answer_auth` round trip reaches
the page (page-reported status) on all three and the probe flips to `Supported`
together with its pin test, or the cause is recorded and the `Partial` reason
text is updated to name CEF 154.

### P8. Input: pen and macOS parity

- **Pen.** `ContactDevice::Pen` reaches CEF as `PointerType::PEN` through
  `send_touch_input` (`drag.rs:76`), but no receipt exists and
  `welding/README.md:197` still says pen is unmodelled. Done when a scripted pen
  contact reaches the page with `pointerType` reported as `pen` on all three
  platforms (page-reported, with a touch control in the same run), and the README
  and matrix row agree.
- **macOS input parity.** CEF consumes `NSEvent`s winit would otherwise see
  (`demo-weld-mac/README.md:51`), so forwarding is thinner than on Windows and
  Linux. Done when real (non-synthetic) pointer, wheel and key events reach the
  DOM through the host path on the Intel and M4 iMacs with page-reported
  receipts, or the structural limit is characterised event by event and the
  README line made specific.

### P9. Page-to-host bridge and the explicit sync seam

- **Renderer-side `weld.message` sender.** The browser-side handlers
  (`windows_cef/cef_backed.rs:475`, `linux_cef/cef_backed.rs:310`,
  `macos_cef/cef_backed.rs:285`) turn a `weld.message` process message into
  `CefSurfaceEvent::WebMessage`, but the only renderer-to-browser sender in
  `welding/src` is the script-result reply (`app.rs:176`), so the page-to-host
  direction has no sender. Done when a page can post a message that arrives as
  an ordered `WebMessage` event on all three platforms (a V8 binding in the
  renderer `CefApp`, page-reported send, host-reported receipt), or the plan
  records that the direction is deliberately CDP-only and the matrix row says so.
- **Explicit sync seam (G3, matrix row 97).** Decide between adopting Graft's
  synchronizer path for CEF frames and documenting why the callback-time copy
  (Windows) and retained-IOSurface aliasing (macOS) make implicit sync correct.
  Done when the decision is recorded in Findings with a measurement (an animating
  page imported for a bounded run with per-frame pixel readback and no torn or
  stale frame, on DX12 and Metal), or an adopted path has receipts.

### P10. Printing

- **macOS printer output.** The probe reports `printer: Supported` off Linux
  (`surface.rs:339`), but only Windows has a physical-output receipt (Brother
  queue, job `Complete`, PrintService event 307). Done when a macOS print job
  reaches a printer or a print-to-file queue with a receipt, or the probe reports
  `Partial` on macOS until then, flipped with its pin test.
- **Linux print (design call).** Linux CEF has no built-in dialog; it needs an
  embedder `CefPrintHandler` with printer UI and spooler, and Weld refuses
  rather than shelling out to `lp`. Done when Q2 is decided; if a handler is
  built, a print job reaches a spooler on the ThinkPad with a receipt.

### P11. Unimplemented host surfaces

Each lands with its probe field and pin test.

- **Cookie-change events.** Probe `Unsupported` (`surface.rs:287`); the matrix
  records only N. Done when CEF 154 is checked for any change hook and the
  result recorded, then either a script-written cookie yields exactly one event
  carrying the cookie on all three, or the probe's reason names the missing CEF
  API.
- **Custom URL schemes.** No scheme handler factory exists in `welding/src` and
  the probe has no field for it. Done when a host registers a scheme through the
  shared `CefApp` (both processes) and a page fetch of it returns the host's
  body in the DOM on all three, with the host reply respecting the callback-thread
  constraint that shaped cookies and downloads; or the plan records the design
  conflict.
- **Popup-browser policy.** `on_before_popup` cancels creation on every
  producer (`windows_cef/cef_backed.rs:271`, `linux_cef/cef_backed.rs:387`,
  `macos_cef/cef_backed.rs:363`) and reports `NewWindowRequested`. Done when Q3
  is decided and the policy is a `CefSurfaceConfig` field with the current
  behaviour as default.
- **Composited single-texture popup mode (deferred).** The separate-surface
  `acquire_popup` is the zero-copy API; compositing needs a third Weld-owned
  texture and two copies per frame. Done when a consuming host asks for it (Q4)
  and the copies are measured, or it is dropped.
- **`parent_window` plumbing.** Weld never sets `parent_window`; plumbing a real
  `HWND` through was shown to arrive (non-`None`) and changed nothing for IME,
  but CEF documents windowless browsers without one may lose dialog and
  context-menu parenting and monitor info. Done when a parent handle is
  configurable on all three producers with a test that it arrives non-`None`,
  and one dialog-parenting behaviour is shown to differ with it, or the item is
  dropped as unneeded.

### P12. Hygiene

- **`Option<&T>` argument audit.** Only DevTools was fixed afterwards (`106da02`,
  `42df5de`). Done when every `Option<&T>` or `None` argument Weld passes to a
  CEF host or browser call (for example `linux_cef/mod.rs:564`, `:899` and their
  twins) is classified against CEF's `ctocpp` wrapper as by-reference-required
  or nullable, required ones are fixed, and the list is in Findings.
- **Vocabulary drift.** `CursorShape`, focus reasons, key and mouse event shapes
  and `NavigationEvent` naming differ between Weld and Scry for no load-bearing
  reason. Done when a table of the differences exists with a decision per item
  (align or leave); alignment is by convention, not a shared crate, and a
  breaking change is ridden on the Scry 0.8 train if Q5 says so.
- **Module size.** The 600-line ceiling no longer holds (`surface.rs` is 1653
  lines). Done when Q6 is decided; the fact is recorded, not acted on.
- **Stale claims.** The `welding/Cargo.toml:54` comment says "Pin the reviewed
  interop ABI exactly" above a caret requirement; `README.md:27`, `:77` and
  `welding/README.md:77-79` describe CI jobs that no longer exist. Done when each
  statement matches the code and receipts (the Cargo comment follows the Graft
  train; the READMEs follow P4).
- **Receipts location.** The CEF 154 Windows receipts sit in
  `docs/receipts/cef154_windows_20261007/` and `docs/receipts/rustfmt_20261006/`,
  outside section 8's `archive_docs/receipts/`. Done when Q7 is decided.

## Open questions

- **Q1. Where does the MSRV lane live?** The deleted `msrv.yml` ran on release
  tags and on demand, not per push (a per-push `-D warnings` lane went red
  whenever the newer toolchain linted something 1.97.1 does not).
  `rust-version` is 1.97.1 while `rust-toolchain.toml` pins 1.99.1, so the lane
  needs an explicit 1.97.1 run. Options: (a) a `scripts/` command in this repo
  run at release, matching the old cadence (recommended); (b) a shared family
  script in another repository, cited by path from here; (c) a per-push local
  hook. Canonical policy: `mere/design_docs/2026-08-12_family_composition_thesis_brief.md`.
- **Q2. Linux print.** Build an embedder `CefPrintHandler` with host-supplied
  printer UI and spooler, or stay `Unsupported` by design (current).
- **Q3. Popup-browser policy shape.** Deny and report (current), allow with a
  host-supplied second producer, or a callback-decided policy; the callback
  thread constraint rules out a synchronous host reply on Linux and macOS.
- **Q4. Composited popup mode.** Build now, on a consumer's request, or drop.
- **Q5. Vocabulary alignment.** Ride the Scry 0.8 breaking release (a
  `welding` 0.16) or leave the names diverged.
- **Q6. Re-split oversized modules?** Seven files exceed 1000 lines
  (`surface.rs` 1653; the three `*_cef/mod.rs` 1115-1232; the three
  `cef_backed.rs` 1012-1056). Re-split, or accept the size.
- **Q7. Receipts under `docs/receipts/`.** Move to `archive_docs/receipts/`
  under the new convention, or leave in place as pre-convention evidence.
- **Q8. Is an NVIDIA proprietary Linux host available** to measure P5, or does
  the claim drop?

## Decisions

- **D1, Wayland-native stays open until a local-script pixel receipt passes
  (2026-11-01), settles P4's status:** Mark: "Open, needs a local receipt". The
  removed `radv-wayland` CI jobs' parity passes are historical; the
  `demo-weld-linux` header saying Wayland is unsupported is fixed only when that
  receipt exists.

  Links: area linux · plans producer_gates · summary Wayland-native is open until a local-script pixel receipt passes; the demo header changes only then.

## Findings

- 2026-11-01: the implicit-modifier DMA-BUF block is closed on wgpu 30.
  `native_frame/vulkan_dmabuf.rs:134` imports `DRM_FORMAT_MOD_INVALID` as
  `DRM_FORMAT_MOD_LINEAR` when the host device has the DMA-BUF feature; wgpu 28
  and 29 keep the typed refusal (`0b0dc5f`).
- 2026-11-01: `CefWindowsSandboxContext` is in `runtime.rs:158` (`61c3c05`);
  `CefRuntime::execute_process_from` takes `(path, sandbox)` (`runtime.rs:248`).
  The ordered `poll_web_event` (`surface.rs:1106`) replaced `poll_navigation_event`
  and `poll_web_message`.
- 2026-11-01: the probe's open or partial rows: cookie-change events
  `Unsupported` (`surface.rs:287`), auth `Partial` (`:316`), popups `Partial`
  (`:324`), Linux printer `Unsupported` (`:341`); every other CEF-backed field is
  `Supported`. macOS print is `Supported` on wiring alone (`:339`).
- 2026-11-01: `weld.message` has browser-side handlers on all three producers
  and no renderer-side sender in `welding/src`; the renderer `CefApp`
  (`app.rs`) handles `weld.eval` only. No README mentions a page-to-host path.
- 2026-11-01: `ContactDevice::Pen` is converted to `PointerType::PEN`
  (`drag.rs:76`); `welding/README.md:197` still says pointer and pen are
  unmodelled.
- 2026-11-01: `welding/Cargo.toml:55` declares `grafting = { version = "0.6.0",
  default-features = false }`, a caret requirement; `Cargo.lock` holds 0.6.0.
  `grafting` 0.6.1 is a recorded breaking release (its default `surfman`
  feature moved Surfman 0.13 to 0.14), which Weld does not pull because it
  builds Grafting with default features off. The Graft 0.7 / Scry 0.8 / Weld
  0.15.1 train covers the requirement.
- 2026-11-01: `WELD_TIMEOUT_SECS` is read by all three demos
  (`demo-weld-win/src/main.rs:957`, `demo-weld-linux/src/main.rs:976`,
  `demo-weld-mac/src/main.rs:835`); `README.md:198-200` states the Windows copy
  and macOS zero-copy lifetimes correctly; `background_color_maps_to_cef_argb`
  is at `surface.rs:484`.
- 2026-11-01: the line counts behind Q6: `surface.rs` 1653, `windows_cef/mod.rs`
  1232, `macos_cef/mod.rs` 1182, `linux_cef/mod.rs` 1115, the three
  `cef_backed.rs` 1056, 1023, 1012, `native_frame/mod.rs` 771.
- 2026-11-01: history was rewritten; commit hashes in the archived plans may not
  be ancestors of `main`. Not ancestors: `4784d07`, `2989de9`, `c65a44e`,
  `770b6bb`, `02fb1cc`, `1269462`; the `welding-v0.13.0` tag peels to `2e59849`,
  cited there as `e865777`. Ancestors: `0b0dc5f`, `61c3c05`, `5327970`,
  `a32955a`, `106da02`, `42df5de`. `welding-v0.15.0` peels to `5e7ce9f`.
- 2026-11-01: the archived plans' CEF 147/148/151 hardware tables are
  historical; only Windows has CEF 154 runtime receipts.

## Progress

- 2026-11-01: cut from the producer parity plan and the CEF accelerated OSR
  plan after a closure audit; both archived whole in `archive_docs/2026-11-01/`
  with corrections marked "Archive note". Draft awaiting the maintainer's review;
  nothing committed.
