# Models

`lib/my_news/models/`

All models use `Sequel::Model`.

## Feed

`MyNews::Models::Feed`

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `url` | Text | Feed URL (unique) |
| `name` | Text | Display name |
| `handler` | Text | Custom handler name |
| `etag` | Text | Last ETag header |
| `last_modified` | Text | Last-Modified header |
| `last_fetched_at` | Text | Timestamp of last fetch |
| `enabled` | Integer | 1 = enabled, 0 = disabled |

**Associations:** `one_to_many :entries`

**Scopes:** `.enabled` -- feeds where `enabled = 1`

## Entry

`MyNews::Models::Entry`

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `feed_id` | Integer | Foreign key to feeds |
| `guid` | Text | Unique entry identifier |
| `title` | Text | Entry title |
| `url` | Text | Entry URL |
| `raw_html` | Text | Raw HTML content |
| `fetched_at` | Text | When the entry was fetched |

**Associations:** `many_to_one :feed`, `one_to_one :article`

## Article

`MyNews::Models::Article`

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `entry_id` | Integer | Foreign key to entries (unique) |
| `markdown` | Text | Normalized markdown content |
| `summary` | Text | LLM-generated summary |
| `simhash` | Integer | 64-bit SimHash fingerprint |
| `cluster_id` | Integer | Duplicate cluster group |
| `is_recurring` | Integer | 1 if recurring topic |
| `processed_at` | Text | When the article was processed |

**Associations:** `many_to_one :entry`

## Bulletin

`MyNews::Models::Bulletin`

| Column | Type | Description |
|--------|------|-------------|
| `id` | Integer | Primary key |
| `theme` | Text | Bulletin theme name |
| `content_md` | Text | Markdown content |
| `content_html` | Text | HTML content |
| `published_at` | Text | Publication timestamp |
| `pushed_freshrss` | Integer | 1 if pushed to FreshRSS |
