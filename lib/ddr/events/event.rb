module Ddr
  module Events
    class Event < ActiveRecord::Base

      # ActiveSupport::Notifications::Instrumenter sets payload[:exception]
      #   to an array of [<exception class name>, <exception message>]
      #   and we want to store this data in a string field.
      serialize :exception, JSON

      # Event date time - for PREMIS and Solr
      DATE_TIME_FORMAT = "%Y-%m-%dT%H:%M:%S.%LZ"

      # set default ordering
      DEFAULT_SORT_ORDER = "event_date_time ASC"
      default_scope { order(DEFAULT_SORT_ORDER) }

      # Outcomes
      SUCCESS = "success"
      FAILURE = "failure"
      OUTCOMES = [SUCCESS, FAILURE]

      # Validation constants
      VALID = "VALID"
      INVALID = "INVALID"

      # For rendering "performed by" when no associated user
      SYSTEM = "SYSTEM"

      DDR_SOFTWARE = "ddr-models #{Ddr::Models::VERSION}"

      class_attribute :description

      validates_presence_of :event_date_time, :pid
      validates :outcome, inclusion: {in: OUTCOMES, message: "\"%{value}\" is not a valid event outcome"}

      after_initialize :set_defaults
      before_save { failure! if exception.present? }

      # Receive message sent by ActiveSupport::Notifications
      def self.call(*args)
        notification = ActiveSupport::Notifications::Event.new(*args)
        payload = notification.payload.dup
        payload[:event_date_time] ||= notification.time
        create do |event|
          event.attributes = payload.select { |k, v| event.has_attribute?(k) }
          yield [event, notification] if block_given?
        end
      end

      # Repository software version -- e.g., "Fedora Repository 3.7.0"
      def self.repository_software
        @@repository_software ||= ActiveFedora::Base.connection_for_pid(0).repository_profile
                                                    .values_at(:repositoryName, :repositoryVersion)
                                                    .join(" ")
      end

      def self.for_object(obj)
        for_pid(obj.pid)
      end

      def self.for_pid(pid)
        where(pid: pid)
      end

      def display_type
        # Ddr::Events::UpdateEvent => "Update"
        @display_type ||= self.class.to_s.split("::").last.sub("Event", "").titleize
      end

      def performed_by
        user_key || SYSTEM
      end

      def comment_or_summary
        comment.present? ? comment : summary
      end

      def success!
        self.outcome = SUCCESS
      end

      def success?
        outcome == SUCCESS
      end

      def failure!
        self.outcome = FAILURE
      end

      def failure?
        outcome == FAILURE
      end

      def object
        @object ||= ActiveFedora::Base.find(pid) if pid
      end

      def object=(obj)
        raise ArgumentError, "Can't set to new object" if obj.new_record?
        self.pid = obj.pid
        @object = obj
      end

      # Override pid setter to clear cached object instance variable
      def pid=(pid)
        @object = nil
        super
      end

      # Return a date/time formatted as a string suitable for use as a PREMIS eventDateTime.
      # Format also works for Solr.
      # Force to UTC.
      def event_date_time_s
        event_date_time.utc.strftime DATE_TIME_FORMAT
      end

      def user=(user)
        self.user_key = user.user_key
      end

      protected

      def set_defaults
        self.attributes = defaults.reject { |attr, val| attribute_present?(attr) }
      end

      def defaults
        { event_date_time: default_event_date_time,
          summary: default_summary,
          software: default_software,
          outcome: default_outcome
        }
      end

      def default_software
        DDR_SOFTWARE
      end

      def default_outcome
        SUCCESS
      end

      def default_summary
        description
      end

      def default_event_date_time
        Time.now.utc
      end

    end
  end
end
