module Ddr
  module Events
    class VirusCheckEvent < Event

      include PreservationEventBehavior
      include ReindexObjectAfterSave

      self.preservation_event_type = :vir
      self.description = "Content file scanned for viruses"

      def to_solr
        { Ddr::IndexFields::LAST_VIRUS_CHECK_ON => event_date_time_s,
          Ddr::IndexFields::LAST_VIRUS_CHECK_OUTCOME => outcome }
      end

      # Message sent by ActiveSupport::Notifications
      def self.call(*args)
        notification = ActiveSupport::Notifications::Event.new(*args)
        result = notification.payload[:result] # Ddr::Services::Antivirus::ScanResult instance
        create(pid: notification.payload[:pid],
               event_date_time: result.scanned_at,
               outcome: result.ok? ? SUCCESS : FAILURE,
               software: result.version,
               detail: result.to_s
               )    
      end

    end
  end
end