# frozen_string_literal: true

module MyNews
  module Summarize
    class Summarizer
      def initialize(config: MyNews.config, on_progress: nil)
        @config = config
        @on_progress = on_progress
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
          unless summary
            @on_progress&.call(:skipped)
            next
          end

          article.update(summary: summary)
          count += 1
          @on_progress&.call(:ok)
        end

        count
      end

      def summarize(markdown)
        text = markdown[0, 4000] # truncate to fit context window
        chat = RubyLLM.chat(model: @model)
        chat.with_instructions(@system_prompt)
        response = chat.ask("Summarize this article concisely:\n\n#{text}")
        response.content
      rescue => e
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
