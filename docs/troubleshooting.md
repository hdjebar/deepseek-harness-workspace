# ❓ Troubleshooting Matrix

| Issue / Symptom | Root Cause | Solution |
| :--- | :--- | :--- |
| **`HTTP 401 Unauthorized` on inference** | Invalid or revoked OpenRouter key | Check key status with `bun run doctor`, then re-run `./setup-dsh.sh` with a valid key from [openrouter.ai/keys](https://openrouter.ai/keys). |
| **`Port 3080` already in use** | Lingering background DSH web process | Run `lsof -ti :3080 \| xargs kill -9` and relaunch `bun run web`. |
| **Missing models in catalog** | Patch has not been synced recently | Execute `bun run sync-models` to pull real-time OpenRouter models. |
| **"Failed to locate openrouter block anchor"** | `cordis.patch.yml` lost its `# Route default model` anchor | Re-run `./setup-dsh.sh` to regenerate the patch layer. |
| **Plugin installation failure** | Network timeout during initial bootstrap | Re-run `./setup-dsh.sh` (backed up to `cordis.patch.yml.bak` if modified). |

---

[← Back to README](../README.md)
