# Development

- [Testing](testing.md) -- running Minitest specs
- [Contributing](contributing.md) -- how to contribute

## Setup

```bash
git clone https://github.com/madbomber/my_news.git
cd my_news
bundle install
```

## Project Structure

```
lib/my_news/
├── cli.rb              # Thor CLI commands
├── config.rb           # Configuration via myway_config
├── db.rb               # SQLite + Sequel setup
├── version.rb
├── config/
│   └── defaults.yml    # Default settings
├── models/             # Sequel models
│   ├── feed.rb
│   ├── entry.rb
│   ├── article.rb
│   └── bulletin.rb
├── fetch/              # Async HTTP fetching
│   ├── fetcher.rb
│   ├── tor_proxy.rb
│   └── handlers/
│       ├── base.rb
│       ├── hacker_news.rb
│       └── mastodon.rb
├── normalize/          # Content extraction
│   ├── normalizer.rb
│   ├── extractor.rb
│   └── converter.rb
├── summarize/          # LLM summarization
│   ├── summarizer.rb
│   └── llm_config.rb
├── cluster/            # Deduplication
│   ├── simhash.rb
│   ├── deduplicator.rb
│   └── recurrence.rb
└── publish/            # Output generation
    ├── publisher.rb
    ├── bulletin_builder.rb
    ├── file_writer.rb
    ├── freshrss.rb
    └── scheduler.rb
```
