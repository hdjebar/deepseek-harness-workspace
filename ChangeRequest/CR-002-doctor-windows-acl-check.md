# CR-002: Real Windows ACL check in `doctor.js` (replace the no-op)

**Status:** 🟡 Proposed — open for challenge
**Priority:** Medium
**Area:** `doctor.js`

## Summary

`doctor.js`'s `checkPermissions()` skips its credential-safety check entirely on Windows (`process.platform !== "win32"` guards at lines 55 and 65) rather than checking anything. That's honest — POSIX `chmod` bits don't exist on NTFS — but it also means the one check DSH advertises as its core security feature ("Zero-Plaintext Security") silently does nothing on Windows, with no warning that it's been skipped. This CR proposes replacing the no-op with an actual ACL-based check, or at minimum surfacing that the check was skipped rather than passing silently.

## Detail

### Problem
Today, on `win32`, `checkPermissions()`'s two branches both fall to the `else` (pass) branch regardless of actual file permissions, because the condition is `process.platform !== "win32" && (mode & 0o077) !== 0` — false on Windows unconditionally. The output line reads `✅ Folder permissions — ... mode 0700` even though that mode value is meaningless on NTFS and nothing was actually verified. A user relying on `bun run doctor`'s green checkmarks would have no signal that credential-file access control isn't actually being verified on their platform.

### Proposed change
Two options, not mutually exclusive:

1. **Minimal (do this regardless of CR-timing on native Windows support):** change the Windows branch from a silent pass to an explicit `info()` line — e.g. `ℹ️ Folder permissions — POSIX check not applicable on Windows; access control not verified`. This is a one-line change and closes the "silently claims success" gap immediately, independent of whether native Windows support (see `docs/windows.md`) ever lands.
2. **Full (once native Windows support exists):** shell out to `icacls <path>` (already the approach documented in `docs/windows.md`'s porting guide) and parse its output to verify the credential file/folder ACL grants access only to the current user, mirroring the intent of the `chmod 600`/`0700` checks. This requires the ACL-lockdown side to actually exist first (i.e., depends on a native `setup-dsh.ps1` per `docs/windows.md`) — there's nothing to verify yet if setup never restricted it.

### Scope
- In scope: `checkPermissions()` in `doctor.js` only.
- Out of scope: implementing the ACL lockdown itself in `setup-dsh.sh`/a future `setup-dsh.ps1` — that's `docs/windows.md`'s porting effort, not this CR. Option 1 above can land independently and immediately; option 2 is blocked on that broader effort.

### Open questions
- Is option 1 alone worth shipping now (closes the "false green checkmark" problem cheaply), with option 2 deferred to whenever native Windows support is actually undertaken? I'd lean yes — no reason to wait on the larger port for a one-line honesty fix.
- `icacls` output parsing is notoriously locale-dependent (localized Windows builds produce different strings) — worth scoping option 2's spec to `Get-Acl`/`.NET` `FileSystemAccessRule` inspection instead of parsing `icacls` text, if/when it's built.

### Effort estimate
Option 1: trivial (single conditional branch). Option 2: small-to-medium, but blocked on other work.
