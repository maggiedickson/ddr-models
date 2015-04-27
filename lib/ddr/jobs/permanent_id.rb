require "ezid-client"

module Ddr
  module Jobs
    module PermanentId

      class Job
        def self.inherited(subclass)
          subclass.instance_variable_set("@queue", :permanent_id)
        end
      end

      class MakeUnavailable < Job
        def self.perform(id, reason = nil)
          identifier = Ezid::Identifier.find(id)
          identifier.unavailable!(reason)
          identifier.save
        end
      end

    end
  end
end
