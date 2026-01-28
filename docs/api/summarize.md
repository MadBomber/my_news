# Summarize API

`lib/my_news/summarize/`

## Summarizer

`MyNews::Summarize::Summarizer`

Orchestrates LLM-based article summarization.

```ruby
summarizer = MyNews::Summarize::Summarizer.new
summarizer.call
```

Processes all articles without a summary, calling the configured LLM provider via `ruby_llm`.

## LlmConfig

`MyNews::Summarize::LlmConfig`

Sets up `RubyLLM` with API keys from environment variables:

```ruby
MyNews::Summarize::LlmConfig.setup(config)
```

Reads `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, and `GEMINI_API_KEY` from the environment.
