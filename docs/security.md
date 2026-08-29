# 🛡️ Security & Sandboxing

> [!IMPORTANT]
> **Strict POSIX Credential Isolation**  
> Credentials reside in `~/.dsh/.credentials.yaml` with strict `0600` permissions (readable/writable only by the owner) inside a `0700` directory. Legacy plaintext `.env` copies are automatically expunged on bootstrap.

> [!NOTE]
> **Runtime Filesystem Sandboxing**  
> Agent file mutations are fenced by DSH's native runtime sandbox policies (`read-only`, `workspace-write`, or `danger-full-access`). Dangerous filesystem mutations outside the workspace boundary require explicit user approval.

---

[← Back to README](../README.md)
