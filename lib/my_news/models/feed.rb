# frozen_string_literal: true

module MyNews
  module Models
    class Feed < Sequel::Model
      set_dataset MyNews.db[:feeds]
      one_to_many :entries, class: "MyNews::Models::Entry"

      dataset_module do
        def enabled
          where(enabled: true)
        end
      end
    end
  end
end
