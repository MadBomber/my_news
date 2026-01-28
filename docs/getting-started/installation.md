# Installation

## Gem Install

```bash
gem install my_news
```

Or add to your Gemfile:

```ruby
gem "my_news"
```

Then:

```bash
bundle install
```

## System Dependencies

- **Ruby** >= 3.2.0 (managed via `rbenv`)
- **SQLite3** -- ships with macOS; on Linux: `apt install libsqlite3-dev`

## LLM API Keys

Summarization requires at least one LLM provider key set as an environment variable:

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
# or
export OPENAI_API_KEY="sk-..."
# or
export GEMINI_API_KEY="..."
```

## Configuration Files

MyNews looks for configuration in the `config/` directory:

| File | Purpose |
|------|---------|
| `config/defaults.yml` | Built-in defaults (bundled with gem) |
| `config/feeds.yml` | Your feed list with per-feed overrides |
| `config/bulletins.yml` | Theme definitions and publish schedule |

See [Configuration](../guides/configuration.md) for details.
