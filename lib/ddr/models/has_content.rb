require 'openssl'

module Ddr
  module Models
    module HasContent
      extend ActiveSupport::Concern

      MASTER_FILE_TYPES = [ "image/tiff" ]

      def master_file?
        if respond_to?(:file_use) && file_use.present?
          file_use == Ddr::Models::HasStructMetadata::FILE_USE_MASTER
        else
          MASTER_FILE_TYPES.include?(content_type)
        end
      end

      included do
        has_file_datastream \
          name: Ddr::Datastreams::CONTENT,
          versionable: true,
          label: "Content file for this object",
          control_group: "M"

        has_file_datastream \
          name: Ddr::Datastreams::EXTRACTED_TEXT,
          type: Ddr::Datastreams::PlainTextDatastream,
          versionable: true,
          label: "Text extracted from the content file",
          control_group: "M"

        has_attributes :original_filename, datastream: "adminMetadata", multiple: false

        include FileManagement

        around_save :update_derivatives, if: :content_changed?

        after_add_file do
          if file_to_add.original_name && file_to_add.dsid == "content"
            self.original_filename = file_to_add.original_name 
          end
        end

        delegate :validate_checksum!, to: :content
      end

      # Convenience method wrapping FileManagement#add_file
      def upload file, opts={}
        add_file(file, Ddr::Datastreams::CONTENT, opts)
      end

      # Set content to file and save
      def upload! file, opts={}
        upload(file, opts)
        save
      end

      def derivatives
        @derivatives ||= Ddr::Managers::DerivativesManager.new(self)
      end

      def content_size
        content.external? ? content.file_size : content.dsSize
      end

      def content_human_size
        ActiveSupport::NumberHelper.number_to_human_size(content_size) if content_size
      end

      def content_type
        content.mimeType
      end

      def content_major_type
        content_type.split("/").first
      end

      def content_sub_type
        content_type.split("/").last
      end

      def content_type= mime_type
        self.content.mimeType = mime_type
      end

      def image?
        content_major_type == "image"
      end

      def pdf?
        content_type == "application/pdf"
      end

      def virus_checks
        Ddr::Events::VirusCheckEvent.for_object(self)
      end

      def content_changed?
        content.external? ? content.dsLocation_changed? : content.content_changed?
      end

      def has_extracted_text?
        extractedText.has_content?
      end

      protected

      def update_derivatives
        yield
        derivatives.update_derivatives(:later)
      end

      def default_content_type
        "application/octet-stream"
      end

    end
  end
end
