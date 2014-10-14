module Ddr
  module Datastreams  
    class PropertiesDatastream < ActiveFedora::OmDatastream

      set_terminology do |t|
        t.root(:path => "fields")
        t.original_filename
        t.permanent_id
      end

      def prefix
        # Squash AF 8.0 deprecation warning
        ""
      end
      
      def self.xml_template
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.fields
        end
        builder.doc
      end

    end
  end
end