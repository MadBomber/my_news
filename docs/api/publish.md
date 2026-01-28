# Publish API

`lib/my_news/publish/`

## Publisher

`MyNews::Publish::Publisher`

Orchestrates the full publish stage: bulletin building, file writing, and FreshRSS push.

```ruby
publisher = MyNews::Publish::Publisher.new
publisher.call
```

## BulletinBuilder

`MyNews::Publish::BulletinBuilder`

Assembles themed bulletins from clustered articles. Groups articles by theme keywords, places recurring topics at the end.

## FileWriter

`MyNews::Publish::FileWriter`

Writes bulletin content to Markdown and HTML files in the configured output directories.

## Freshrss

`MyNews::Publish::Freshrss`

Pushes bulletins to FreshRSS via the Fever API using Faraday HTTP POST requests.

## Scheduler

`MyNews::Publish::Scheduler`

Runs the full pipeline on a cron schedule using `rufus-scheduler`.

```ruby
scheduler = MyNews::Publish::Scheduler.new
scheduler.start  # Blocks, runs pipeline at configured times
```
