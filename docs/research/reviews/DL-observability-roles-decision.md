# Decision: APPROVED — DL-observability-roles

**Date:** 2026-07-30
**Approver:** change-approver
**Review source:** docs/research/reviews/DL-observability-roles-review-r8.md

## Gate evaluation

| Gate | Condition | Value | Threshold | Result |
|------|-----------|-------|-----------|--------|
| G1: Overall confidence | review-360 overall score | 83 | > 80 | PASS |
| G2: Correctness floor | Correctness score | 85 | >= 70 | PASS |
| G2: Red-team resistance floor | Red-team resistance score | 83 | >= 70 | PASS |
| G2: Safety floor | Safety score | 87 | >= 70 | PASS |
| G3: No unresolved blockers | Blocking items | 0 | 0 | PASS |
| Check-on-checker | Critical findings vs. headline | — | No contradiction | PASS |

## Verdict: APPROVED

**Rationale:**

All three gates pass on the round-8 report's own numbers. G1: overall confidence 83 clears the >80 bar — the first of eight rounds to do so. G2: all three critical-dimension floors clear >=70 with margin (Correctness 85, Red-team resistance 83, Safety 87; critical_floor = 83). G3: the report's own full rounds-1–7 closure ledger, re-audited fresh this round, confirms none of the 19 prior blocking items (5+5+5+3+3+3+3 across rounds 1–6, verified again at r7 and r8) reopened, and all three of round-7's numbered blocking items — broker JUDGE-membership/isolation, named channel-authentication mechanism with honest granularity, and the `InferenceClient` Protocol with destination-pinning — are independently verified closed by concrete artifact evidence (DATA-LAYER.md:326, :312–317, :349). The reviewer's verdict is explicit: "ready-for-approval," "none rises to a blocking change required to sustain the score above 80."

**Check-on-the-checker applied to the two new round-8 findings.** I scanned the report body, not just the summary table, specifically for the two new findings the calibration dimension surfaces: (1) the `STUDY-hermes-agent.md` §5 citation overstates its source — the study documents "an authenticated UDS" + "token auth" but not the specific "OS peer-credential verification" / "constant-time comparison" DATA-LAYER attributes to it; (2) "the open-relay/exfiltration path is closed by construction" (:317) overclaims scope — destination-arbitrariness is closed, but content-borne exfiltration of legitimately-SOLVE-visible data to a registered provider is not, per the round's own adversarial objection. Neither finding is tagged critical, blocking, must-fix, or severity>=HIGH anywhere in the report; the reviewer repeatedly and explicitly frames both as non-blocking, narrower and lower-severity than the round-7 findings they replace ("neither residual reopens a closed round 1–7 finding," "narrower, lower-severity residual, adjacent to but distinct from what closed," verdict item list explicitly labeled "non-blocking"). The invariant's override trigger requires a critical/blocking-tagged item coexisting with score>80 — that condition is not met here: these are calibration/honesty defects (citation precision, phrasing scope) that the reviewer itself priced into a real 5-point Calibration dip (83→78) rather than suppressing. The headline score is not contradicted by a buried critical finding; it already reflects these findings' cost. No override applies.

All gates pass. **Approved**, carrying the review's own residuals forward as advisories per established precedent (matching the pattern used in S16, S17/S18, S19, S20, and prior DL-observability-roles-adjacent gates in this project).

## Advisories (non-blocking — track, do not gate)

1. **Citation-accuracy correction (Calibration finding #1).** Correct or narrow the `STUDY-hermes-agent.md` §5 citation for the channel-authentication mechanism: either cite only what the source actually documents (an authenticated UDS + token auth) or independently justify peer-credential verification and constant-time comparison as this document's own design choice rather than attributing them to the study.
2. **Scope qualification (Calibration finding #2 / the round's adversarial objection).** Qualify "the open-relay/exfiltration path is closed by construction" (:317) to state explicitly what it closes (destination arbitrariness to an attacker-controlled endpoint) and what it does not (content-borne exfiltration of legitimately-SOLVE-visible data to a registered provider) — one sentence, in the pattern this document has used successfully elsewhere (pre-M3 notes, authentication-not-reachability scoping).
3. **Provider registry schema/config surface.** State the registry's concrete schema/config location (where it lives, how entries are added, whether registration is itself logged/gated) — the natural companion to the now-defined `InferenceClient` Protocol. No `mdlp.toml` block or §5/§7 entry currently exists for it.
4. **`B_obs` default.** Give the emit-buffer bound `B_obs` a stated default, matching this document's own convention for every other bounded parameter (e.g. `w_rejected`, "default 30 days").
5. **Packaging stub + correlation_id mapping table.** Add a dependency/packaging stub for the broker process to §7's extras list (currently none), and consider tying the `correlation_id` kind-typing prose (:327) to an explicit `kind → id-type` mapping table rather than descriptive prose alone.
6. **Carried, untouched:** whether non-model-call tool invocations get the same JUDGE-composed-wrapper treatment as model calls remains unstated (open since round 6/7, still open at r8).

## Next step

**Authorized for commit.** This decision record authorizes the change described in
`DL-observability-roles-review-r8.md` — DATA-LAYER.md §11 "revised r8" plus its anchored
deltas (§1 pointer, §2.1 bundle composition + `InferenceClient` Protocol, §5 trace/score
schemas, §6 `rebuild_analytics` clause, §6.1 exemption-list additions, §7 extras) — to be
committed. The change-approver does not apply the edit; the committing agent or user must
reference this record when creating the commit, and should carry advisories 1–6 above into
a follow-up (non-blocking) revision or the BUILD-SPECS companion item, consistent with how
prior gates in this project (S16, S17/S18, S19, S20) have handled ready-for-approval
residuals.
