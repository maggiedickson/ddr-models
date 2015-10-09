module Ddr::Models
  class Metadata

    def values(term)
      self.send(term)
    end

    # Update term with values
    # Note that empty values (nil or "") are rejected from values array
    def set_values(term, values)
      if values.respond_to?(:reject!)
        values.reject! { |v| v.blank? }
      else
        values = nil if values.blank?
      end
      begin
        self.send("#{term}=", values)
      rescue NoMethodError
        raise ArgumentError, "No such term: #{term}"
      end
    end

    # Add value to term
    # Note that empty value (nil or "") is not added
    def add_value(term, value)
      begin
        unless value.blank?
          values = values(term).to_a << value
          set_values term, values
        end
      rescue NoMethodError
        raise ArgumentError, "No such term: #{term}"
      end
    end

  end
end