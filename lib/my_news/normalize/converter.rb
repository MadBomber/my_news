# frozen_string_literal: true

require "reverse_markdown"

# Patch reverse_markdown 2.1.1 for Ruby 4.0 frozen string compatibility.
# The gem uses frozen string literals ("", "\n\n", etc.) with << mutation.
# We dup the result of treat so the accumulator always appends mutable strings.
module ReverseMarkdown
  module Converters
    class Base
      def treat_children(node, state)
        node.children.inject(+"") do |memo, child|
          memo << (+treat(child, state))
        end
      end
    end
  end
end

module MyNews
  module Normalize
    class Converter
      def convert(html)
        return "" if html.nil? || html.strip.empty?

        md = ReverseMarkdown.convert(html, unknown_tags: :bypass, github_flavored: true)
        clean(md)
      end

      private

      def clean(markdown)
        markdown
          .gsub(/\n{3,}/, "\n\n")   # collapse excessive blank lines
          .gsub(/^\s+$/, "")         # remove whitespace-only lines
          .strip
      end
    end
  end
end
