module Ddr
  module Auth
    extend ActiveSupport::Autoload
    extend Deprecation

    autoload :Ability
    autoload :AbilityDefinitions
    autoload :AbilityFactory
    autoload :AbstractAbility
    autoload :Affiliation
    autoload :AffiliationGroups
    autoload :AnonymousAbility
    autoload :AuthContext
    autoload :AuthContextFactory
    autoload :DetachedAuthContext
    autoload :DynamicGroups
    autoload :EffectivePermissions
    autoload :EffectiveRoles
    autoload :FailureApp
    autoload :Group
    autoload :GrouperGateway
    autoload :Groups
    autoload :InheritedRoles
    autoload :LdapGateway
    autoload :Permissions
    autoload :RemoteGroups
    autoload :ResourceRoles
    autoload :RoleBasedAccessControlsEnforcement
    autoload :Roles
    autoload :SuperuserAbility
    autoload :User
    autoload :WebAuthContext

    autoload_under 'ability_definitions' do
      autoload :AdminSetAbilityDefinitions
      autoload :AliasAbilityDefinitions
      autoload :AttachmentAbilityDefinitions
      autoload :CollectionAbilityDefinitions
      autoload :ComponentAbilityDefinitions
      autoload :DatastreamAbilityDefinitions
      autoload :EventAbilityDefinitions
      autoload :ItemAbilityDefinitions
      autoload :PublicationAbilityDefinitions
      autoload :LockAbilityDefinitions
      autoload :RoleBasedAbilityDefinitions
      autoload :SuperuserAbilityDefinitions
    end

    # Name of group whose members are authorized to act as superuser
    mattr_accessor :superuser_group

    # Name of group whose members are authorized to create Collections
    mattr_accessor :collection_creators_group

    # Name of group whose members are authorized to act as a metadata manager
    mattr_accessor :metadata_managers_group

    # Group of which everyone (including anonymous users) is a member
    def self.everyone_group
      Deprecation.warn(Ddr::Auth,
                       "`Ddr::Auth.everyone_group` is deprecated and will be removed in ddr-models 3.0." \
                       " Use `Ddr::Auth::Groups::PUBLIC` instead.")
      Groups::PUBLIC
    end

    # Group of authenticated users
    def self.authenticated_users_group
      Deprecation.warn(Ddr::Auth,
                       "`Ddr::Auth.authenticated_users_group` is deprecated and will be removed in ddr-models 3.0." \
                       " Use `Ddr::Auth::Groups::REGISTERED` instead.")
      Groups::REGISTERED
    end

    def self.const_missing(name)
      if name == :Superuser
        Deprecation.warn(Ddr::Auth,
                         "`Ddr::Auth::Superuser` is deprecated and will be removed in ddr-models 3.0." \
                         " Use `Ddr::Auth::SuperuserAbility` instead.")
        return SuperuserAbility
      end
      super
    end

    # Whether to require Shibboleth authentication
    mattr_accessor :require_shib_user_authn do
      false
    end

    # Grouper gateway implementation
    mattr_accessor :grouper_gateway do
      GrouperGateway
    end

    # LDAP gateway implementation
    mattr_accessor :ldap_gateway do
      LdapGateway
    end

    mattr_accessor :default_ability do
      "::Ability"
    end

    def self.repository_group_filter
      if filter = ENV["REPOSITORY_GROUP_FILTER"]
        return filter
      end
      raise Ddr::Models::Error, "The \"REPOSITORY_GROUP_FILTER\" environment variable is not set."
    end

  end
end
