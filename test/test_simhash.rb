# frozen_string_literal: true

require "test_helper"

class TestSimhash < Minitest::Test
  def test_identical_text_produces_same_hash
    text = "the quick brown fox jumps over the lazy dog"
    a = MyNews::Cluster::Simhash.compute(text)
    b = MyNews::Cluster::Simhash.compute(text)
    assert_equal a, b
  end

  def test_similar_text_has_low_hamming_distance
    a = MyNews::Cluster::Simhash.compute("the quick brown fox jumps over the lazy dog near the river")
    b = MyNews::Cluster::Simhash.compute("the quick brown fox jumps over the lazy dog near the stream")
    distance = MyNews::Cluster::Simhash.hamming_distance(a, b)
    assert_operator distance, :<, 15
  end

  def test_different_text_has_high_hamming_distance
    a = MyNews::Cluster::Simhash.compute("ruby programming language for web development and scripting tasks")
    b = MyNews::Cluster::Simhash.compute("quantum physics explores subatomic particles and wave functions deeply")
    distance = MyNews::Cluster::Simhash.hamming_distance(a, b)
    assert_operator distance, :>, 5
  end

  def test_empty_text_returns_zero
    assert_equal 0, MyNews::Cluster::Simhash.compute("")
  end

  def test_hamming_distance_zero_for_same_value
    assert_equal 0, MyNews::Cluster::Simhash.hamming_distance(42, 42)
  end
end
