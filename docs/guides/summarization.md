# Summarization

MyNews uses the `ruby_llm` gem for unified access to multiple LLM providers.

## Supported Providers

| Provider | Env Variable | Example Model |
|----------|-------------|---------------|
| Anthropic | `ANTHROPIC_API_KEY` | `claude-sonnet-4-20250514` |
| OpenAI | `OPENAI_API_KEY` | `gpt-4o` |
| Google | `GEMINI_API_KEY` | `gemini-2.0-flash` |

## Configuration

In `defaults.yml`:

```yaml
llm:
  provider: anthropic
  model: claude-sonnet-4-20250514
  max_tokens: 300
```

## How It Works

1. The summarizer loads unsummarized articles from the database
2. Each article's markdown content is sent to the configured LLM
3. A system prompt styled as an Economist editor guides the summary format
4. The concise summary is stored on the `Article` record

```ruby
# Internal flow
chat = RubyLLM.chat(model: config.llm_model)
chat.with_instructions(system_prompt)
response = chat.ask("Summarize this article concisely:\n\n#{markdown}")
article.update(summary: response.content)
```

## System Prompt

The summarization prompt is stored in `prompts/economist_editor.md` and instructs the LLM to produce concise, informative summaries in the style of The Economist.

## Running

```bash
my_news summarize
```

This processes all articles that don't yet have a summary.
