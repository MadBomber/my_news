# MyNews

A Ruby gem that transforms 200+ RSS feeds into themed bulletins published 3x daily. The pipeline fetches, normalizes, summarizes (via LLM), deduplicates, and publishes — outputting to both FreshRSS and local Markdown/HTML files.

<table><tr>
<td width="340">
  <img src="docs/assets/images/my_news.gif" alt="MyNews" width="320">
  <a href="https://madbomber.github.io/my_news">Full Documentation</a>
</td>
<td>
**Key Features**

- Async concurrent fetching with ETag caching and rate limiting
- Full-text extraction and HTML-to-Markdown normalization
- LLM-powered summarization (OpenAI, Anthropic, Gemini via `ruby_llm`)
- SimHash deduplication and recurring topic detection
- Themed bulletin assembly with scheduled publishing
- FreshRSS Fever API integration
- SQLite persistence with FTS5 full-text search
- Tor proxy support for restricted feeds

</td>
</tr></table>


## Installation

Add to your Gemfile:

```ruby
gem "my_news"
```

Then run:

```bash
bundle install
```

## Pipeline Architecture

Each stage runs independently via CLI or chained together:

```
fetch → normalize → summarize → cluster → publish
```

| Stage | Description |
|-------|-------------|
| **fetch** | Async HTTP with ETag caching, rate limiting, per-feed handlers |
| **normalize** | Readability full-text extraction, HTML-to-Markdown conversion |
| **summarize** | LLM summarization via `ruby_llm` (multi-provider) |
| **cluster** | SimHash deduplication, recurring topic detection |
| **publish** | Themed bulletins to FreshRSS and local Markdown/HTML files |

## Usage

```bash
# Run the full pipeline
my_news run

# Run individual stages
my_news fetch
my_news normalize
my_news summarize
my_news cluster
my_news publish

# Schedule automatic 3x daily runs
my_news schedule
```

## Configuration

Configuration files live in `config/`:

- `feeds.yml` — Feed list with per-feed overrides
- `settings.yml` — Global settings (LLM provider, proxy, schedule)
- `bulletins.yml` — Theme definitions and publish schedule

### LLM Setup

```yaml
# config/settings.yml
llm:
  provider: anthropic
  model: claude-sonnet-4-20250514
  max_tokens: 300
```

API keys are read from environment variables: `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`.

## Development

```bash
bin/setup          # Install dependencies
bundle exec rake   # Run tests (Minitest)
bin/console        # Interactive console with gem loaded
```

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/madbomber/my_news).

## License

Available as open source under the [MIT License](https://opensource.org/licenses/MIT).
