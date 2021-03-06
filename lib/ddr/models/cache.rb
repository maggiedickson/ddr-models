module Ddr::Models
  class Cache < Hash

    def get(key)
      self[key]
    end

    def put(key, value)
      self[key] = value
    end

    def with(options, &block)
      merge!(options)
      block_result = yield
      reject! { |k, v| options.include?(k) }
      block_result
    end

  end
end
