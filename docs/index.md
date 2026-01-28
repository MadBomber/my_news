# MyNews

**RSS feed pipeline that transforms 200+ feeds into themed bulletins published 3x daily.**

MyNews fetches RSS feeds concurrently, extracts full-text content, summarizes articles via LLM, deduplicates with SimHash clustering, and publishes themed bulletins to FreshRSS and local files.

## Pipeline

<div class="pipeline-overview">
  <div class="phase bg-fetch">FETCH</div>
  <span class="arrow">&#x25B6;</span>
  <div class="phase bg-normalize">NORMALIZE</div>
  <span class="arrow">&#x25B6;</span>
  <div class="phase bg-summarize">SUMMARIZE</div>
  <span class="arrow">&#x25B6;</span>
  <div class="phase bg-cluster">CLUSTER</div>
  <span class="arrow">&#x25B6;</span>
  <div class="phase bg-publish">PUBLISH</div>
</div>

| Stage | What it does |
|-------|-------------|
| **Fetch** | Async HTTP with ETag caching, rate limiting, Tor proxy support |
| **Normalize** | Readability full-text extraction, HTML-to-Markdown conversion |
| **Summarize** | LLM summarization via `ruby_llm` (OpenAI, Anthropic, Gemini) |
| **Cluster** | SimHash deduplication, recurring topic detection |
| **Publish** | Themed bulletin assembly, FreshRSS Fever API, Markdown+HTML output |

## Quick Links

- [Installation](getting-started/installation.md) -- get up and running
- [Quick Start](getting-started/quick-start.md) -- first pipeline run
- [CLI Reference](cli/index.md) -- all commands
- [Configuration](guides/configuration.md) -- defaults.yml, feeds.yml, bulletins.yml
- [API Reference](api/index.md) -- module documentation
- [Examples](examples/index.md) -- 7 runnable examples

## Requirements

- Ruby >= 3.2.0
- SQLite3
- LLM API key (OpenAI, Anthropic, or Gemini) for summarization
