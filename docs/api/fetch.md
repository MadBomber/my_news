# Fetch API

`lib/my_news/fetch/`

## Fetcher

`MyNews::Fetch::Fetcher`

Orchestrates concurrent feed fetching using `async-http`.

```ruby
fetcher = MyNews::Fetch::Fetcher.new
results = fetcher.call
# => { feed_id => { status: :ok, new_entries: 5 }, ... }
```

**Behavior:**

- Loads enabled feeds from the database
- Fetches concurrently (configurable via `fetch.concurrency`)
- Sends `If-None-Match` / `If-Modified-Since` headers for ETag caching
- Delegates to per-feed handlers when configured
- Stores new entries in the `entries` table

## TorProxy

`MyNews::Fetch::TorProxy`

SOCKS5 proxy wrapper for routing requests through Tor.

Configured via `fetch.tor.enabled`, `fetch.tor.host`, `fetch.tor.port` in defaults.yml.

## Handlers

`MyNews::Fetch::Handlers`

### Base

`MyNews::Fetch::Handlers::Base` -- abstract base class for custom feed handlers.

### HackerNews

`MyNews::Fetch::Handlers::HackerNews` -- extracts linked article URLs from HN RSS items and fetches full content.

### Mastodon

`MyNews::Fetch::Handlers::Mastodon` -- handles Mastodon/Fediverse feed items.
