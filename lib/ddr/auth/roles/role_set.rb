require "delegate"

module Ddr
  module Auth
    module Roles
      #
      # Wraps a set of Roles (ActiveTriples::Term)
      #
      class RoleSet < SimpleDelegator

        # Grants roles - i.e., adds them to the role set
        #   Note that we reject roles that are included because
        #   ActiveTriples::Term#<< does not support isomorphism. 
        #   https://github.com/ActiveTriples/ActiveTriples/issues/42
        # @example - default scope (:resource)
        #   grant type: :curator, person: "bob"
        # @example - explicit scope
        #   grant type: :curator, person: "sue", scope: :policy
        # @param roles [Array<Ddr::Auth::Roles::Role, Hash>] the roles to grant
        def grant(*roles)
          self << coerce(roles).reject { |r| include?(r) }
        end

        # Return true/false depending on whether the role has been granted
        # @param role [Ddr::Auth::Roles::Role, Hash] the role
        # @return [Boolean] whether the role has been granted
        def granted?(role)
          include? coerce(role)
        end

        # Revokes roles - i.e., removes them from the role set
        #   Note that we have to destroy resources on the 
        #   ActiveTriples::Term because Term#delete does not
        #   support isomorphism.
        #   https://github.com/ActiveTriples/ActiveTriples/issues/42
        # @example
        #   revoke type: :curator, agent: "bob", scope: :resource
        # @param role [Ddr::Auth::Roles::Role, Hash] the role to revoke
        def revoke(*roles)
          coerce(roles).each do |role|
            if role_index = find_index(role)
              self[role_index].destroy
            end
          end
        end

        # Replace the current roles in the role set with new roles
        # @param roles [Array<Ddr::Auth::Roles::Role, Hash>] the roles to grant
        def replace(*roles)
          revoke_all
          # XXX Not sure why we have to use __getobj__ here
          __getobj__.set coerce(roles)
        end

        # Remove all roles from the role set
        def revoke_all          
          delete(*__getobj__)
        end

        def to_a
          map.to_a
        end

        def where(criteria)
          query.where(criteria)
        end

        private

        def query
          Query.new(self)
        end

        def coerce(role)
          case role
          when Array
            role.map { |r| coerce(r) }
          when Role
            role
          else
            Ddr::Auth::Roles.build_role(role)
          end
        end

      end
    end
  end
end
