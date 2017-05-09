module Ddr::Index
  class QueryResultPage < SimpleDelegator

    def has_next?
      ( page_start + per_page ) < page_total
    end

  end
end
