# frozen_string_literal: true

module MyNews
  module Models
    class Entry < Sequel::Model
      set_dataset MyNews.db[:entries]
      many_to_one :feed, class: "MyNews::Models::Feed"
    end
  end
end
