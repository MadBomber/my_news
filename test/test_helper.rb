# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "my_news"

require "minitest/autorun"

# Setup in-memory database for tests
module TestHelper
  def setup_test_db
    config_dir = File.expand_path("../config", __dir__)
    MyNews.setup(config_dir: config_dir, db_path: ":memory:")
  end
end

# Ensure at least one setup so require doesn't fail for CLI test
MyNews.setup(db_path: ":memory:")
