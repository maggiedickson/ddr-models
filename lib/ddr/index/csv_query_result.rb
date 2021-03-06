require "csv"

module Ddr::Index
  class CSVQueryResult < AbstractQueryResult

    MAX_ROWS         = 10**8 # Just set to a really high number :)
    CSV_MV_SEPARATOR = ";"

    delegate :headers, :to_s, :to_csv, to: :table

    def delete_empty_columns!
      table.by_col!.delete_if { |c, vals| vals.all?(&:nil?) }
    end

    def each(&block)
      table.by_row!.each(&block)
    end

    def [](index_or_header)
      table.by_col_or_row![index_or_header]
    end

    def table
      @table ||= CSV.parse(data, csv_opts)
    end

    def csv_opts
      { headers:        csv_headers,
        converters:     [convert_semicolons, convert_escaped_newlines],
        return_headers: false,
        write_headers:  true,
      }
    end

    def solr_csv_opts
      { "csv.mv.separator" => CSV_MV_SEPARATOR,
        "csv.header"       => solr_csv_header?,
        "rows"             => solr_csv_rows,
        "wt"               => "csv",
      }
    end

    def query_field_headings
      query.fields.map { |f| f.respond_to?(:heading) ? f.heading : f.to_s }
    end

    def csv_headers
      query.fields.empty? ? :first_row : query_field_headings
    end

    def solr_csv_header?
      csv_headers == :first_row
    end

    def solr_csv_rows
      query.rows || MAX_ROWS
    end

    def solr_csv_params
      params.merge(solr_csv_opts)
    end

    def data
      Connection.get("select", params: solr_csv_params)
    end

    def convert_semicolons
      lambda { |f| f.gsub(/\\#{CSV_MV_SEPARATOR}/, CSV_MV_SEPARATOR) rescue f }
    end

    def convert_escaped_newlines
      lambda { |f| f.gsub(/\\r/, "\r").gsub(/\\n/, "\n") rescue f }
    end

  end
end
