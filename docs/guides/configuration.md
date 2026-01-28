# Configuration

MyNews uses `myway_config` for layered configuration with environment-specific overrides.

## Config Files

| File | Location | Purpose |
|------|----------|---------|
| `defaults.yml` | Bundled with gem | Default settings for all environments |
| `feeds.yml` | `config/feeds.yml` | Feed URLs and per-feed overrides |
| `bulletins.yml` | `config/bulletins.yml` | Theme definitions and publish schedule |

## defaults.yml

```yaml
defaults:
  database:
    path: db/my_news.db

  fetch:
    concurrency: 10
    user_agent: "MyNews/0.1 (+https://github.com/madbomber/my_news)"
    timeout: 30
    tor:
      enabled: false
      host: "127.0.0.1"
      port: 9050

  llm:
    provider: anthropic
    model: claude-sonnet-4-20250514
    max_tokens: 300

  freshrss:
    url: ""
    username: ""
    api_key: ""

  output:
    markdown_dir: output/markdown
    html_dir: output/html

  schedule:
    times:
      - "07:00"
      - "13:00"
      - "19:00"
    timezone: America/Chicago

development:
  database:
    path: db/my_news_dev.db

test:
  database:
    path: ":memory:"

production:
  database:
    path: db/my_news.db
  fetch:
    concurrency: 20
```

## feeds.yml

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

## bulletins.yml

```yaml
themes:
  - name: Tech
    keywords: [ruby, python, javascript, rust, go, programming]
  - name: AI & ML
    keywords: [ai, llm, machine learning, neural, gpt, claude]
  - name: Security
    keywords: [security, vulnerability, breach, exploit, cve]
```

## Environment Variables

LLM API keys are read from the environment:

| Variable | Provider |
|----------|----------|
| `ANTHROPIC_API_KEY` | Anthropic (Claude) |
| `OPENAI_API_KEY` | OpenAI (GPT) |
| `GEMINI_API_KEY` | Google (Gemini) |

## Accessing Config in Code

```ruby
MyNews.setup
config = MyNews.config

config.database_path      # => "db/my_news.db"
config.fetch_concurrency  # => 10
config.llm_model          # => "claude-sonnet-4-20250514"
config.schedule_times     # => ["07:00", "13:00", "19:00"]
config.feeds              # => [{"url" => "...", "name" => "..."}]
config.themes             # => [{"name" => "Tech", "keywords" => [...]}]
```
