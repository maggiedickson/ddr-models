require "csv"

module Ddr::Index
  class CSVQueryResult < AbstractQueryResult

    MAX_ROWS = 10**8

    COL_SEP    = CSV::DEFAULT_OPTIONS[:col_sep].freeze
    QUOTE_CHAR = CSV::DEFAULT_OPTIONS[:quote_char].freeze

    SOLR_CSV_OPTS = {
      "csv.header"       => "false",
      "csv.mv.separator" => ";",
      "wt"               => "csv",
    }.freeze

    CSV_OPTS = {
      return_headers: true,
      write_headers:  true,
    }.freeze

    attr_reader :csv_opts, :solr_csv_opts

    def initialize(query, **opts)
      super(query)

      @solr_csv_opts = SOLR_CSV_OPTS.dup
      @solr_csv_opts[:rows] ||= MAX_ROWS

      @csv_opts = CSV_OPTS.dup
      @csv_opts[:headers] = query.fields.map(&:label)

      # Set column separator and quote character consistently
      @csv_opts[:col_sep]    = @solr_csv_opts["csv.separator"]    = opts.fetch(:col_sep, COL_SEP)
      @csv_opts[:quote_char] = @solr_csv_opts["csv.encapsulator"] = opts.fetch(:quote_char, QUOTE_CHAR)
    end

    def csv
      CSV.new(data, csv_opts)
    end

    def each
      csv.each
    end

    def to_s
      csv.string
    end

    private

    def csv_params
      params.merge(solr_csv_opts)
    end

    def data
      conn.get "select", params: csv_params
    end

  end
end
