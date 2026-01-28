# Database

MyNews uses SQLite via the Sequel ORM with FTS5 full-text search.

## Schema

```sql
CREATE TABLE feeds (
  id INTEGER PRIMARY KEY,
  url TEXT NOT NULL UNIQUE,
  name TEXT,
  handler TEXT,
  etag TEXT,
  last_modified TEXT,
  last_fetched_at TEXT,
  enabled INTEGER DEFAULT 1
);

CREATE TABLE entries (
  id INTEGER PRIMARY KEY,
  feed_id INTEGER REFERENCES feeds(id),
  guid TEXT NOT NULL,
  title TEXT,
  url TEXT,
  raw_html TEXT,
  fetched_at TEXT NOT NULL,
  UNIQUE(feed_id, guid)
);

CREATE TABLE articles (
  id INTEGER PRIMARY KEY,
  entry_id INTEGER REFERENCES entries(id) UNIQUE,
  markdown TEXT NOT NULL,
  summary TEXT,
  simhash INTEGER,
  cluster_id INTEGER,
  is_recurring INTEGER DEFAULT 0,
  processed_at TEXT NOT NULL
);

CREATE VIRTUAL TABLE articles_fts USING fts5(
  title, markdown, summary,
  content='articles',
  content_rowid='id',
  tokenize='porter'
);

CREATE TABLE bulletins (
  id INTEGER PRIMARY KEY,
  theme TEXT NOT NULL,
  content_md TEXT,
  content_html TEXT,
  published_at TEXT,
  pushed_freshrss INTEGER DEFAULT 0
);
```

## FTS5 Full-Text Search

The `articles_fts` virtual table provides Porter-stemmed full-text search across article titles, markdown content, and summaries.

```ruby
# Search via Sequel
MyNews.db[:articles_fts]
  .where(Sequel.lit("articles_fts MATCH ?", "ruby performance"))
  .limit(10)
  .select(:rowid, :title, :summary)
  .all
```

Or via CLI:

```bash
my_news search "ruby performance" --limit 20
```

## Sequel ORM

Models use `Sequel::Model` and live in `lib/my_news/models/`:

- `MyNews::Models::Feed`
- `MyNews::Models::Entry`
- `MyNews::Models::Article`
- `MyNews::Models::Bulletin`
