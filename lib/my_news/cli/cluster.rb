# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "cluster", "Deduplicate and detect recurring topics"
    def cluster
      MyNews.setup
      puts "Clustering articles..."
      clustered = Cluster::Deduplicator.new.call
      recurring = Cluster::Recurrence.new.call
      puts "Clustered #{clustered || 0} articles into duplicate groups"
      puts "Flagged #{recurring} recurring topics"
    end
  end
end
