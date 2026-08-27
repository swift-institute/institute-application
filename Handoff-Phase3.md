# Phase 3 Handoff — compile/test convergence over the four-layer substrate

Written 2026-08-27 by the Phase 2 outer-loop session at the seal of the molecules
decomposition. This document plus `Decomposition.json` (same directory, same
branch) is everything the Phase 3 coordinator needs; the predecessor chat is not
required.

## Where things stand

Phase 1 (sealed in `Migration.json`): 468-repository mechanical cutover into the
four organizations. Phase 2 (sealed in `Decomposition.json`, state `complete`):
all 209 sealed swift-molecules packages carry exactly one disposition — 112
atoms transferred to `swift-atoms` in canonical shape (single domain module `X`;
products exactly `X`, `X Standard Library Integration`, `X Apple Foundation
Integration`; AFI is the only Foundation-touching module), 96 molecules (12
substrate-woven swift-x kept in place + 84 sealed swift-x-y), 1 developer-tool
(`swift-institute/swift-linter`). 190 additive seam-molecule repositories were
created in swift-molecules. Org census verifies: swift-atoms = 112 repos;
swift-molecules = 292 active (102 pre-existing + 190 new).

Everything was done to a **structural-only bar**: organization placement,
splits, and Package.swift products/targets/dependencies are correct; nothing
was compiled or tested, and lane notes per package (in the ledger) enumerate
the expected red. GitHub transfer redirects keep old coordinates resolving.

Control: this worktree (`migration/four-layer-cutover` of
`swift-institute/institute-application`, tracked on origin — re-create from
origin if the /private/tmp checkout is gone). The ledger is the single
persistence artifact; keep it that way (lean entries, commit per package or
batch, push per wave).

## Phase 3 mission

Raise the bar from structural to semantic, bottom-up over the NEW graph:
每 package must resolve, build, and pass its tests before it is booked green.
Order: tranche 0 below first, then zero-dep atoms upward, then the 190 seam
molecules, then the substrate molecules-in-place. Book evidence in a
`convergence` section of `Decomposition.json` (package, headSHA, build/test
result, changes made).

### Tranche 0 — audit repairs (before any compile work touches these)

A read-only audit of all 112 atoms (recorded as concern
`atoms-audit-2026-08-27` in the ledger) found 97 clean, 0 shape violations,
and two flaw clusters. Resolve them first:

1. **Memory-representation hole — the only five hard atom→molecule edges.**
   Relocate the type content of `swift-memory-heap`, `swift-bit-index`, and
   `swift-affine-geometry` (and evaluate `swift-memory-cursor`,
   `swift-buffer-linear`) down into atoms — either promote the repos to
   swift-atoms after reduction, or absorb the constitutive types into the atoms
   that store them. This erases the edges held by swift-string, swift-path,
   swift-memory, swift-geometry, swift-lexer.
2. **Frontend-family re-adjudication.** `swift-text → swift-source →
   swift-token → swift-diagnostic → swift-lexer`, plus `swift-test`,
   `swift-range`, `swift-cursor`, `swift-layout`: each is definitionally
   derived from domains beneath it. Demote to swift-molecules (transfer back is
   cheap and preserves IDs) or slim to a genuinely native core with the derived
   surface seamed out (e.g. slim Test core + swift-test-sample/-snapshot).
3. **Dependency surgery**: swift-parser drops/seams its incidental swift-text
   edge; swift-pool swaps swift-dimension for swift-tagged; swift-storage stops
   riding other atoms' SLI products; sweep the 13 stale swift-molecules URL
   pins (swift-complex, swift-cursor, swift-test) to swift-atoms coordinates.

### Main loop — per-package convergence

For each package bottom-up: fix per-file imports left by deleted `@_exported`
umbrellas (MemberImportVisibility / InternalImportsByDefault); move or delete
test functions referencing extracted seams; resolve cross-package access to
`package`-visibility members (public API or code motion); validate cross-module
Codable/conformance rewrites; fix module-vs-type name shadowing (`Fixed`,
`Slab_Buffer_Slab`, `ASCII.ASCII.Case`, …) and stale product names in
consumers; canonicalize all dependency URLs to final org homes. Atoms
additionally: no Foundation outside AFI; aim at the Institute Embedded profile.

### Machinery that worked in Phase 2 (reuse the pattern)

- Outer loop (coordinator): computes eligibility from the ledger, dispatches
  waves, verifies lane-claimed head SHAs against live repos before booking,
  owns all transfers and every ledger write. Lanes never touch the ledger,
  never transfer, never force-push, never merge PRs, never bypass gates, never
  handle key material — put that verbatim in every brief.
- Inner lanes: one package per lane, institute-inner-loop agents dispatched via
  a Workflow script (~5–15 parallel), structured results with full 40-char SHAs
  read back from git. Wave latency was 4–10 minutes.
- Verification catches real errors: one lane reported a 41-char SHA typo; four
  were cut mid-flight by a usage limit and were cleanly re-run in a fresh
  scratch root (never reuse a dead lane's checkout).
- GitHub transfer strips each repo ruleset's `OrganizationAdmin` bypass —
  restore it after every transfer or pushes to the transferred repo start
  bouncing:
  `gh api -X PUT repos/<org>/<repo>/rulesets/<id> --input -` with
  `{"bypass_actors":[{"actor_id":null,"actor_type":"OrganizationAdmin","bypass_mode":"always"}]}`.
- Direct pushes to main are authorized under the pre-release posture (the
  remote prints a bypass notice; that is expected). Never force-push.

## After Phase 3 (sketch)

- **Phase 4 — standards + compositions convergence**: re-point and green L3
  (authority orgs + swift-standards convergence packages; convergence roots
  drop the legacy `-standard` suffix), then L4 swift-compositions (263 repos,
  including Phase 1's 24 principal-accepted resolution blockers), migrating all
  consumers to canonical identities bottom-up.
- **Phase 5 — enforcement and freeze**: move the canonical shape into
  machinery (swift-linter rules, Institute validators, CI re-armed — the
  ci-ok checks bypassed throughout get turned back on), regenerate
  Institute.json/workspace/docs to the four-layer reality, then freeze
  swift-atoms (protections without routine bypass; changes become exceptional
  events) and retire redirect-era coordinates.

## End-goal of the project

A four-layer ecosystem where dependencies point strictly downward, the graph is
acyclic, and every capability has exactly one semantic owner: L1 swift-atoms as
an immortal, unchanging substrate of indisputable code; L2 swift-molecules
owning bounded integrations between atoms; L3 swift-standards owning externally
governed specifications; L4 swift-compositions owning everything that exists
only by relating domains. Because the bottom layer never changes, correctness
composes: higher layers trust the substrate absolutely, change is
compartmentalized to its semantic owner, and the uniform shape and naming laws
keep the ecosystem mechanically legible to CI, the linter, and agents.
