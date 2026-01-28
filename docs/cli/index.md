# CLI Reference

MyNews provides a Thor-based CLI. All commands are invoked as `my_news <command>`.

## Pipeline Commands

| Command | Description |
|---------|-------------|
| `fetch` | Fetch all enabled RSS feeds |
| `normalize` | Convert raw entries to markdown articles |
| `summarize` | Summarize articles via LLM |
| `cluster` | Deduplicate and detect recurring topics |
| `publish` | Build and publish themed bulletins |
| `pipeline` | Run full pipeline: fetch, normalize, summarize, cluster, publish |
| `schedule` | Run the full pipeline on a cron schedule (3x/day by default) |

## Search

```bash
my_news search QUERY [--limit N]
```

Full-text search across articles using FTS5. Default limit is 10 results.

## Feed Management

| Command | Description |
|---------|-------------|
| `feeds [--all]` | List all feeds and their status |
| `feed_add URL [--name NAME] [--handler HANDLER]` | Add a new feed |
| `feed_remove URL` | Remove a feed and its entries |
| `feed_toggle URL` | Enable or disable a feed |

## Status

```bash
my_news status
```

Displays pipeline statistics:

- Feed counts (enabled/total)
- Entry, article, bulletin counts
- Summarization and clustering progress
- Duplicate group and recurring topic counts
- Last 24 hours activity
