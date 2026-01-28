# Custom Handlers

Feed handlers customize how specific feeds are parsed. Built-in handlers exist for Hacker News and Mastodon.

## Built-in Handlers

| Handler | Feed Type | Behavior |
|---------|-----------|----------|
| `hacker_news` | Hacker News RSS | Extracts linked article URL, fetches full content |
| `mastodon` | Mastodon/Fediverse | Handles toots, thread unwinding |

## Writing a Custom Handler

Create a new file in `lib/my_news/fetch/handlers/`:

```ruby
# lib/my_news/fetch/handlers/my_site.rb
module MyNews
  module Fetch
    module Handlers
      class MySite < Base
        def process(entry)
          # entry is a parsed RSS item
          # Return a hash with :title, :url, :raw_html
          {
            title:    entry.title,
            url:      entry.link,
            raw_html: fetch_full_content(entry.link)
          }
        end

        private

        def fetch_full_content(url)
          # Custom logic to fetch and extract content
          response = HTTP.get(url)
          response.body.to_s
        end
      end
    end
  end
end
```

## Registering a Handler

Reference the handler by its snake_case name in `feeds.yml`:

```yaml
feeds:
  - url: https://my-site.com/feed.xml
    name: My Site
    handler: my_site
```

The handler class name is derived by converting `my_site` to `MySite` and looking in the `Handlers` namespace.
