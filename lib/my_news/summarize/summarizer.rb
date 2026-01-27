# frozen_string_literal: true

require "debug_me"

module MyNews
  module Summarize
    class Summarizer
      include DebugMe

      def initialize(config: MyNews.config)
        @config = config
        LlmConfig.setup
        @model = config.llm_model
        @max_tokens = config.llm_max_tokens
        @system_prompt = load_prompt
      end

      def call
        articles = unsummarized_articles
        count = 0

        articles.each do |article|
          summary = summarize(article.markdown)
          next unless summary

          article.update(summary: summary)
          count += 1
        end

        debug_me "Summarized #{count} articles"
        count
      end

      def summarize(markdown)
        text = markdown[0, 4000] # truncate to fit context window
        chat = RubyLLM.chat(model: @model)
        chat.with_instructions(@system_prompt)
        response = chat.ask("Summarize this article concisely:\n\n#{text}")
        response.content
      rescue => e
        debug_me "LLM error: #{e.message}"
        nil
      end

      private

      def unsummarized_articles
        Models::Article.where(summary: nil).all
      end

      def load_prompt
        path = File.expand_path("../../../prompts/economist_editor.md", __dir__)
        File.read(path)
      end
    end
  end
end
