# Feeds

## Adding Feeds

### Via config file

Add entries to `config/feeds.yml`:

```yaml
feeds:
  - url: https://lobste.rs/rss
    name: Lobsters
  - url: https://feeds.arstechnica.com/arstechnica/index
    name: Ars Technica
  - url: https://news.ycombinator.com/rss
    name: Hacker News
    handler: hacker_news
```

### Via CLI

```bash
my_news feed_add https://lobste.rs/rss --name "Lobsters"
my_news feed_add https://news.ycombinator.com/rss --name "HN" --handler hacker_news
```

## Managing Feeds

```bash
# List all enabled feeds
my_news feeds

# Include disabled feeds
my_news feeds --all

# Toggle a feed on/off
my_news feed_toggle https://lobste.rs/rss

# Remove a feed and its entries
my_news feed_remove https://lobste.rs/rss
```

## Per-Feed Options

| Option | Description |
|--------|-------------|
| `url` | RSS/Atom feed URL (required) |
| `name` | Display name |
| `handler` | Custom handler name (`hacker_news`, `mastodon`) |

## ETag Caching

The fetcher stores `ETag` and `Last-Modified` headers from each feed response. On subsequent fetches, these are sent back to avoid re-downloading unchanged content. Feeds returning `304 Not Modified` are skipped.
