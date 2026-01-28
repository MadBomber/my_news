# Pipeline Architecture

## Overview

<div class="pipeline-detailed">
  <div class="stage-col bg-fetch">
    <div class="stage-title">FETCH</div>
    <div class="step">Load feeds from config</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Async HTTP requests</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">ETag / Last-Modified caching</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Parse RSS / Atom XML</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Store entries in SQLite</div>
  </div>
  <div class="stage-col bg-normalize">
    <div class="stage-title">NORMALIZE</div>
    <div class="step">Load unprocessed entries</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Readability extraction</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">HTML → Markdown</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Create Article records</div>
  </div>
  <div class="stage-col bg-summarize">
    <div class="stage-title">SUMMARIZE</div>
    <div class="step">Load unsummarized articles</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Build LLM prompt</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Call provider via ruby_llm</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Store summary on article</div>
  </div>
  <div class="stage-col bg-cluster">
    <div class="stage-title">CLUSTER</div>
    <div class="step">Compute SimHash fingerprints</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Group by hamming distance</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Assign cluster IDs</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Detect recurring topics</div>
  </div>
  <div class="stage-col bg-publish">
    <div class="stage-title">PUBLISH</div>
    <div class="step">Group articles by theme</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Build bulletin content</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Write Markdown + HTML files</div>
    <div class="step-arrow">&#x25BC;</div>
    <div class="step">Push to FreshRSS via Fever API</div>
  </div>
</div>

## Stage Details

### Fetch

- Uses `async` and `async-http` for concurrent requests (default: 10 concurrent)
- Respects `ETag` and `Last-Modified` headers to skip unchanged feeds
- Custom handlers for sites needing special parsing (Hacker News, Mastodon)
- Optional Tor SOCKS5 proxy support
- Stores raw HTML entries in the `entries` table

### Normalize

- Extracts full-text content using Readability algorithm via `nokogiri`
- Converts clean HTML to Markdown using `reverse_markdown`
- Creates `Article` records linked back to source `Entry`

### Summarize

- Uses `ruby_llm` gem for unified access to OpenAI, Anthropic, and Gemini
- Applies an Economist-style editor system prompt
- Generates concise summaries stored on each `Article`

### Cluster

- Computes 64-bit SimHash fingerprints from article text
- Groups articles by hamming distance threshold
- Assigns `cluster_id` to duplicate groups
- Detects recurring topics by comparing against articles from the last 3 days

### Publish

- Groups articles into themed bulletins based on `bulletins.yml` configuration
- Recurring topics placed at the end of each bulletin
- Writes Markdown and HTML output files
- Pushes bulletins to FreshRSS via the Fever API

## Design Decisions

| Decision | Rationale |
|----------|-----------|
| `ruby_llm` gem | Single gem for all LLM providers; no custom adapter code |
| Sequel over ActiveRecord | Lighter weight, better FTS5 support, no Rails dependency |
| `async` gem over threads | Structured concurrency via Fibers for 200+ HTTP requests |
| Pure Ruby SimHash | Avoids native dependencies; 64-bit fingerprint is fast enough for hundreds of articles |
| Discrete CLI commands | Each pipeline stage independently runnable or chained via `pipeline` |
| Fever API for FreshRSS | Simple HTTP POST, no special client needed |
