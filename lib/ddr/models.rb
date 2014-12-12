require 'ddr/models/engine'
require 'ddr/models/version'

# Awful hack to make Hydra::AccessControls::Permissions accessible
$: << Gem.loaded_specs['hydra-access-controls'].full_gem_path + "/app/models/concerns"

require 'active_record'

require 'hydra-core'
require 'hydra/derivatives'
require 'hydra/validations'

require 'ddr/actions'
require 'ddr/auth'
require 'ddr/datastreams'
require 'ddr/events'
require 'ddr/index_fields'
require 'ddr/metadata'
require 'ddr/notifications'
require 'ddr/utils'
require 'ddr/workflow'

module Ddr
  module Models
    extend ActiveSupport::Autoload

    autoload :Base
    autoload :AccessControllable
    autoload :Describable
    autoload :EventLoggable
    autoload :Error
    autoload :ChecksumInvalid, 'ddr/models/error'
    autoload :FixityCheckable
    autoload :Governable
    autoload :HasAttachments
    autoload :HasChildren
    autoload :HasContent
    autoload :HasContentMetadata
    autoload :HasProperties
    autoload :HasRoleAssignments
    autoload :HasThumbnail
    autoload :HasWorkflow
    autoload :Indexing
    autoload :FileManagement
    autoload :Licensable
    autoload :MintedId
    autoload :PermanentIdentification
    autoload :SolrDocument
    
    # Base directory of external file store
    mattr_accessor :external_file_store      

    # Regexp for building external file subpath from hex digest
    mattr_accessor :external_file_subpath_regexp
      
    # Yields an object with module configuration accessors
    def self.configure
      yield self
    end

    def self.external_file_subpath_pattern= (pattern)
      unless /^-{1,2}(\/-{1,2}){0,3}$/ =~ pattern
        raise "Invalid external file subpath pattern: #{pattern}"
      end
      re = pattern.split("/").map { |x| "(\\h{#{x.length}})" }.join("")
      self.external_file_subpath_regexp = Regexp.new("^#{re}")
    end

  end
end

Dir[Ddr::Models::Engine.root.to_s + "/app/models/*.rb"].each { |m| require m }
