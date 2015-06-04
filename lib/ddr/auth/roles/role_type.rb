module Ddr
  module Auth
    module Roles
      class RoleType

        attr_reader :title, :description, :permissions
        alias_method :label, :title

        def initialize(title, description, permissions)
          @title, @description, @permissions = title, description, permissions
          @permissions.freeze
          freeze
        end

        def to_s
          title
        end

      end
    end
  end
end