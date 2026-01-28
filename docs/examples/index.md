# Examples

Seven runnable examples in the `examples/` directory demonstrate each pipeline stage.

## Running Examples

```bash
bundle exec ruby examples/01_basic_setup.rb
```

## Example List

### 01 -- Basic Setup

`examples/01_basic_setup.rb`

Connects to the database, creates tables, and inspects the schema. Shows how `MyNews.setup` initializes everything.

### 02 -- Single Feed Fetch

`examples/02_single_feed_fetch.rb`

Fetches a single feed (Lobsters), stores entries, and queries results via Sequel models.

### 03 -- Full Pipeline Report

`examples/03_full_pipeline_report.rb`

Fetches all configured feeds concurrently. Demonstrates ETag caching behavior across two runs and per-feed statistics.

### 04 -- Normalize Entries

`examples/04_normalize_entries.rb`

Fetches Ars Technica, then normalizes raw HTML entries into clean Markdown articles. Shows before/after content.

### 05 -- Summarize Articles

`examples/05_summarize_articles.rb`

Fetches a feed, normalizes entries, then summarizes articles via the configured LLM. Requires an API key.

### 06 -- Cluster & Dedup

`examples/06_cluster_dedup.rb`

Seeds synthetic duplicate content to demonstrate SimHash fingerprinting, hamming distance calculation, and cluster assignment.

### 07 -- Full Publish

`examples/07_full_publish.rb`

Runs the complete pipeline from fetch through publish. Outputs themed bulletins as Markdown and HTML files.
