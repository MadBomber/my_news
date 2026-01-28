# frozen_string_literal: true

require "ruby_llm"

module MyNews
  module Summarize
    module LlmConfig
      module_function

      def setup
        RubyLLM.configure do |c|
          c.openai_api_key    = ENV["OPENAI_API_KEY"]
          c.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
          c.gemini_api_key    = ENV["GEMINI_API_KEY"]
          c.ollama_api_base   = ENV.fetch("OLLAMA_API_BASE", "http://localhost:11434")
        end
      end
    end
  end
end
