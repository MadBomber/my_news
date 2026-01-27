# frozen_string_literal: true

require "test_helper"

class TestMyNews < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MyNews::VERSION
  end
end
