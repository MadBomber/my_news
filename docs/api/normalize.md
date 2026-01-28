# Normalize API

`lib/my_news/normalize/`

## Normalizer

`MyNews::Normalize::Normalizer`

Orchestrates the normalization of raw HTML entries into Markdown articles.

```ruby
normalizer = MyNews::Normalize::Normalizer.new
count = normalizer.call
# => number of articles created
```

## Extractor

`MyNews::Normalize::Extractor`

Uses the Readability algorithm (via Nokogiri) to extract the main content from HTML pages, stripping navigation, ads, and boilerplate.

## Converter

`MyNews::Normalize::Converter`

Converts clean HTML to Markdown using the `reverse_markdown` gem.
