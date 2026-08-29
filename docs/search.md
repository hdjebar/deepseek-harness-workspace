# 🔍 Zero-Cost Web Search (`@liustack/modsearch`)

Standard AI agent harnesses often rely on expensive search APIs (Tavily, Bing, Google Search API) with separate monthly quotas and rate limits. This workspace integrates **[`@liustack/modsearch`](https://www.npmjs.com/package/@liustack/modsearch)** directly into the runtime profile.

### 🌟 Why `@liustack/modsearch`?
* 🆓 **Zero API Keys & Zero Cost:** Queries the web without requiring any subscription or credit card.
* 🌐 **Multi-Engine Aggregator:** Automatically queries and falls back between DuckDuckGo, Bing, and open web indexers.
* 🕷️ **Clean Web Scraping:** Uses Firecrawl-compatible web extraction to deliver sanitized, readable Markdown directly into the agent's reasoning loop.
* ⚡ **Zero-Code Override:** Pre-configured in `~/.dsh/cordis.patch.yml` to automatically intercept and replace default paid search providers:

```yaml
# Disable default paid search in favor of free ModSearch
- id: web-search-deepseek
  disabled: true

- id: web
  config:
    searchProvider: modsearch
```

---

[← Back to README](../README.md)
