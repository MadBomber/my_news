# Testing

MyNews uses Minitest. Tests live in the `test/` directory.

## Running Tests

```bash
# Run all tests
bundle exec rake test

# Or equivalently
bundle exec rake

# Run a single test file
bundle exec ruby test/test_my_news.rb
```

## Test Database

Tests use an in-memory SQLite database (configured in `defaults.yml` under the `test` environment):

```yaml
test:
  database:
    path: ":memory:"
```

## Writing Tests

```ruby
require "test_helper"

class TestMyFeature < Minitest::Test
  def setup
    MyNews.setup(env: :test)
  end

  def test_something
    assert_equal expected, actual
  end
end
```
