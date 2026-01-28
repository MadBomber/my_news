# Publishing

The publish stage assembles clustered articles into themed bulletins and outputs them to files and FreshRSS.

## Output Formats

### Markdown Files

Written to `output/markdown/` (configurable):

```
output/markdown/2025-01-27_morning_tech.md
output/markdown/2025-01-27_morning_ai.md
```

### HTML Files

Written to `output/html/` (configurable):

```
output/html/2025-01-27_morning_tech.html
output/html/2025-01-27_morning_ai.html
```

## FreshRSS Integration

MyNews pushes bulletins to FreshRSS via the Fever API.

Configure in `defaults.yml`:

```yaml
freshrss:
  url: "https://freshrss.example.com/api/fever.php"
  username: "your_username"
  api_key: "your_api_key"
```

## Bulletin Structure

Each bulletin is organized by theme (defined in `bulletins.yml`):

1. New articles matching theme keywords, grouped by cluster
2. Recurring topics appended at the end

## Running

```bash
my_news publish
```
