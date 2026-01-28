# MyNews

A Ruby gem that transforms 200+ RSS feeds into themed bulletins published 3x daily. The pipeline fetches, normalizes, summarizes (via LLM), deduplicates, and publishes — outputting to both FreshRSS and local Markdown/HTML files.

<table><tr>
<td width="400">
  <video controls width="380">
    <source src="assets/images/my_news.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
</td>
<td>
<h2>Key Features</h2>

<li> Async concurrent fetching with ETag caching and rate limiting
<li> Full-text extraction and HTML-to-Markdown normalization
<li> LLM-powered summarization (OpenAI, Anthropic, Gemini via `ruby_llm`)
<li> SimHash deduplication and recurring topic detection
<li> Themed bulletin assembly with scheduled publishing
<li> FreshRSS Fever API integration
<li> SQLite persistence with FTS5 full-text search
Mli> Proxy support for restricted feeds
</td>
</tr></table>

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
