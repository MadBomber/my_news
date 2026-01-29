# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "pipeline", "Run full pipeline: fetch -> normalize -> summarize -> cluster -> publish"
    def pipeline
      MyNews.setup
      puts "Running full pipeline..."
      invoke :fetch
      invoke :normalize
      invoke :summarize
      invoke :cluster
      invoke :publish
      puts "Pipeline complete"
    end

    map "run" => :pipeline
  end
end
