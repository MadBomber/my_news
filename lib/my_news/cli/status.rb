# frozen_string_literal: true

module MyNews
  class CLI < Thor
    desc "status", "Show pipeline status and statistics"
    def status
      MyNews.setup

      feeds_total    = Models::Feed.count
      feeds_enabled  = Models::Feed.enabled.count
      entries_total  = Models::Entry.count
      articles_total = Models::Article.count
      summarized     = Models::Article.exclude(summary: nil).count
      clustered      = Models::Article.exclude(cluster_id: nil).count
      recurring      = Models::Article.where(is_recurring: true).count
      bulletins      = Models::Bulletin.count

      # Recent activity
      cutoff_24h = Time.now - (24 * 3600)
      entries_24h  = Models::Entry.where { fetched_at > cutoff_24h }.count
      articles_24h = Models::Article.where { processed_at > cutoff_24h }.count
      bulletins_24h = Models::Bulletin.where { published_at > cutoff_24h }.count

      # Cluster stats
      cluster_counts = Models::Article.exclude(cluster_id: nil).group_and_count(:cluster_id).all
      dup_groups = cluster_counts.select { |r| r[:count] > 1 }

      puts <<~HEREDOC

        ╔══════════════════════════════════════════════╗
        ║           Pipeline Status                    ║
        ╠══════════════════════════════════════════════╣
        ║                                              ║
        ║  Feeds:          #{feeds_enabled.to_s.rjust(5)} enabled / #{feeds_total.to_s.rjust(5)} total  ║
        ║  Entries:        #{entries_total.to_s.rjust(24)}  ║
        ║  Articles:       #{articles_total.to_s.rjust(24)}  ║
        ║  Summarized:     #{summarized.to_s.rjust(24)}  ║
        ║  Clustered:      #{clustered.to_s.rjust(24)}  ║
        ║  Duplicate groups: #{dup_groups.size.to_s.rjust(22)}  ║
        ║  Recurring:      #{recurring.to_s.rjust(24)}  ║
        ║  Bulletins:      #{bulletins.to_s.rjust(24)}  ║
        ║                                              ║
        ║  --- Last 24 hours ---                       ║
        ║  New entries:    #{entries_24h.to_s.rjust(24)}  ║
        ║  New articles:   #{articles_24h.to_s.rjust(24)}  ║
        ║  Bulletins sent: #{bulletins_24h.to_s.rjust(24)}  ║
        ║                                              ║
        ╚══════════════════════════════════════════════╝

      HEREDOC
    end
  end
end
