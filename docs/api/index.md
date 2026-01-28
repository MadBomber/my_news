# API Reference

Module-level documentation for the MyNews gem.

## Modules

| Module | Description |
|--------|-------------|
| [Fetch](fetch.md) | Async feed fetching with caching and handlers |
| [Normalize](normalize.md) | Full-text extraction and HTML-to-Markdown conversion |
| [Summarize](summarize.md) | LLM-powered article summarization |
| [Cluster](cluster.md) | SimHash deduplication and recurring topic detection |
| [Publish](publish.md) | Bulletin assembly, file output, FreshRSS integration |
| [Models](models.md) | Sequel models for Feed, Entry, Article, Bulletin |

## Top-Level

```ruby
MyNews.setup                  # Initialize database and configuration
MyNews.setup(db_path: "...")  # Custom database path
MyNews.db                     # Sequel database connection
MyNews.config                 # Configuration object
```
