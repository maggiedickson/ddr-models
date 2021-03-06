require "virtus"
require "forwardable"

module Ddr::Index
  class Query
    include Virtus.model
    extend Forwardable
    extend Deprecation

    attribute :q,       String
    attribute :fields,  Array[FieldAttribute], default: [ ]
    attribute :filters, Array[Filter],         default: [ ]
    attribute :sort,    Array[String],         default: [ ]
    attribute :rows,    Integer

    delegate [:count, :docs, :ids, :each_id, :all] => :result
    delegate :params => :query_params

    def self.build(*args, &block)
      new.tap do |query|
        query.build(*args, &block)
      end
    end

    def initialize(**args, &block)
      super(**args)
      if block_given?
        build(&block)
      end
    end

    def inspect
      "#<#{self.class.name} q=#{q.inspect}, filters=#{filters.inspect}," \
      " sort=#{sort.inspect}, rows=#{rows.inspect}, fields=#{fields.inspect}>"
    end

    def to_s
      URI.encode_www_form(params)
    end

    def pids
      Deprecation.warn(QueryResult, "`pids` is deprecated; use `ids` instead.")
      ids
    end

    def each_pid(&block)
      Deprecation.warn(QueryResult, "`each_pid` is deprecated; use `each_id` instead.")
      each_id(&block)
    end

    def result
      QueryResult.new(self)
    end

    def csv
      CSVQueryResult.new(self)
    end

    def filter_clauses
      filters.map(&:clauses).flatten
    end

    def query_params
      QueryParams.new(self)
    end

    def build(*args, &block)
      QueryBuilder.new(self, *args, &block)
      self
    end

    def ==(other)
      other.instance_of?(self.class) &&
        other.q == self.q &&
        other.fields == self.fields &&
        other.filters == self.filters &&
        other.rows == self.rows &&
        other.sort == self.sort
    end

  end
end
