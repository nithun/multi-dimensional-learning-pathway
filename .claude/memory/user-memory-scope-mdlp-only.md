<!-- RESCUED 2026-07-30 from the USER-LEVEL Claude memory store (~/.claude/projects/.../memory/), which does
     NOT survive a Claude login change. Preserved verbatim below so a new login can re-save it as a user memory.
     Its substance is also enforced as L-012 in lessons.md and stated in CONTINUE-HERE.md §2. -->

---
name: scope-mdlp-only
description: Manage only the Multi-Dimensional Learning Pathway research project — never the turing-agents repo; cross-project info is passed manually by the user
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 146d9309-f2f4-4f08-8187-1cefa9bebc29
---

My management scope is **only** `/Users/samyoga/Documents/Claude/Projects/Multi-Dimensional Learning Pathway`. The `/Users/samyoga/dev/turing-agents` repo is **not** mine to manage — it has its own framework/curator. I overstepped by writing into it, modifying its board/scripts/memory, and committing to it (including committing its own unrelated memory-log lines).

**Why:** The user said plainly, after I committed to turing-agents: "you manage only [MDLP path], this not turing agents." Reaffirmed 2026-07-02: turing-agents is "a research implementation I am doing. Don't modify any code over there. If you want to share any information, I will pass it manually for any other projects."

**How to apply:** Keep all deliverables — including docs/designs *about* the turing-agents implementation — in the MDLP research repo (e.g. `docs/research/`). Do **not** write to, modify, or run git in `/Users/samyoga/dev/turing-agents` under any circumstances — not even if a doc (e.g. HANDOVER-v2) points builders there; the user is the builder there, not me. When the implementation needs something from this repo's research, produce it as a doc here and tell the user — **they carry it across manually**. Never touch another repo's `.claude/memory`, task board, or commit history. Housing decision: HANDOVER-v2 §3 resolved RELEASE-PLAN [D-2] toward turing-agents — the v2 artifact is cut there by the user.
