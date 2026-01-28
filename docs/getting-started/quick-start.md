# Quick Start

## 1. Create a feeds file

```yaml
# config/feeds.yml
feeds:
  - url: https://lobste.rs/rss
    name: Lobsters
  - url: https://feeds.arstechnica.com/arstechnica/index
    name: Ars Technica
```

## 2. Run the full pipeline

```bash
my_news pipeline
```

This runs all five stages in sequence: fetch, normalize, summarize, cluster, publish.

## 3. Check results

```bash
# View output files
ls output/markdown/
ls output/html/

# Search articles
my_news search "ruby performance"

# Check pipeline status
my_news status
```

## Running Individual Stages

Each stage can be run independently:

```bash
my_news fetch       # pull feeds, store raw entries
my_news normalize   # convert raw HTML to markdown
my_news summarize   # generate LLM summaries
my_news cluster     # deduplicate and detect recurring topics
my_news publish     # build and publish themed bulletins
```

## Interactive Console

```bash
bin/console
```

This starts an IRB session with the gem loaded.
