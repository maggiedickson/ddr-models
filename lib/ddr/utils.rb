require 'openssl'

module Ddr::Utils

  def self.digest content, algorithm
    raise TypeError, "Algorithm must be a string: #{algorithm.inspect}" unless algorithm.is_a?(String)
    digest_class = OpenSSL::Digest.const_get(algorithm.sub("-", "").to_sym)
    digest_class.new(content).to_s
  rescue NameError => e
    raise ArgumentError, "Invalid algorithm: #{algorithm}"
  end

  # Return a mime type for the file, using the file_name if necessary
  # file can be a File object or file path (String)
  # @return [String] the mime type or default
  def self.mime_type_for(file, file_name=nil)
    return file.content_type if file.respond_to?(:content_type) # E.g., Rails uploaded file
    path = file_name || file_path(file) rescue nil
    mime_types = MIME::Types.of(path) rescue []                 # MIME::Types.of blows up on nil
    mime_types.empty? ? Ddr::Models.default_mime_type : mime_types.first.content_type
  end

  def self.file_or_path?(file)
    file_path(file)
  rescue ArgumentError
    false
  end

  def self.file_path?(file)
    # length is a sanity check
    file.is_a?(String) && (file.length < 1024) && File.exist?(file)
  end

  def self.file_path(file)
    if file.respond_to?(:path)
      File.absolute_path(file.path)
    elsif file_path?(file)
      file
    else
      raise ArgumentError, "Argument is neither a File nor a path to an existing file."
    end
  end

  def self.file_name_for(file)
    if file.respond_to?(:original_filename) && file.original_filename.present?
      file.original_filename
    else
      File.basename file_path(file)
    end
  end

  def self.file_uri?(uri)
    return false unless uri
    URI.parse(uri).scheme == "file"
  end

  def self.sanitize_filename(file_name)
    return unless file_name
    raise ArgumentError, "file_name argument must be a string" unless file_name.is_a?(String)
    raise ArgumentError, "file_name argument must not include path" if file_name.include?(File::SEPARATOR)
    file_name.gsub(/[^\w\.\-]/,"_")
  end

  # Return file path for URI string
  # Should reverse .path_to_uri
  # "file:/path/to/file" => "/path/to/file"
  # @param uri [String] The URI string to pathify
  # @return [String] the file path
  def self.path_from_uri(uri_string)
    uri = URI.parse(uri_string)
    unless uri.scheme == "file"
      raise ArgumentError, "URI does not have the file: scheme."
    end
    URI.unescape(uri.path)
  end

  # Return URI string for file path
  # Should reverse .path_from_uri
  # "/path/to/file" => "file:/path/to/file"
  # @param path [String] the file path
  # @return [String] the file: URI string
  def self.path_to_uri(path)
    uri = URI.parse URI.escape(path)
    uri.scheme = "file"
    uri.to_s
  end

  def self.ds_as_of_date_time(ds)
    ds.create_date_string
  end

  # Find an object with a given identifier and return its PID.
  # Returns the PID if a single object is found.
  # Returns nil if no object is found.
  # Raises Ddr::Models::Error if more than one object is found.
  # Options can be provided to limit the scope of matching objects
  #   model: Will only consider objects of that model
  #   collection: Will only consider objects that either are that collection or which are
  #      direct children of that collection (i.e., effectively searches a collection and its
  #      items for an object with the given identifier)
  def self.pid_for_identifier(identifier, opts={})
    model = opts.fetch(:model, nil)
    collection = opts.fetch(:collection, nil)
    objs = []
    ActiveFedora::Base.find_each( { Ddr::Index::Fields::IDENTIFIER_ALL => identifier }, { :cast => true } ) { |o| objs << o }
    pids = []
    objs.each { |obj| pids << obj.pid }
    if model.present?
      objs.each { |obj| pids.delete(obj.pid) unless obj.is_a?(model.constantize) }
    end
    if collection.present?
      objs.each do |obj|
        pids.delete(obj.pid) unless obj == collection || obj.parent == collection
      end
    end
    case pids.size
    when 0
      nil
    when 1
      pids.first
    else
      raise Ddr::Models::Error, I18n.t('ddr.errors.multiple_object_matches', :criteria => "identifier #{identifier}")
    end
  end

  # Returns the reflection object for a given model name and relationship name
  # E.g., relationship_object_reflection("Item", "parent") returns the reflection object for
  # an Item's parent relationship.  This reflection object can then be used to obtain the
  # class of the relationship object using the reflection_object_class(reflection) method below.
  def self.relationship_object_reflection(model, relationship_name)
    reflection = nil
    if model
      begin
        reflections = model.constantize.reflections
      rescue NameError
        # nothing to do here except that we can't return the appropriate reflection
      else
        reflections.each do |reflect|
          if reflect[0].eql?(relationship_name.to_sym)
            reflection = reflect
          end
        end
      end
    end
    return reflection
  end

  # Returns the class associated with the :class_name attribute in the options of a reflection
  # E.g., reflection_object_class(relationship_object_reflection("Item", "parent")) returns the
  # Collection class.
  def self.reflection_object_class(reflection)
    reflection_object_model = nil
    klass = nil
    if reflection[1].options[:class_name]
      reflection_object_model = reflection[1].options[:class_name]
    else
      reflection_object_model = ActiveSupport::Inflector.camelize(reflection[0])
    end
    if reflection_object_model
      begin
        klass = reflection_object_model.constantize
      rescue NameError
        # nothing to do here except that we can't return the reflection object class
      end
    end
    return klass
  end

  # Returns a string suitable to index as a Solr date
  # @param dt [Date, DateTime, Time] the date/time
  # @return [String]
  def self.solr_date(dt)
    return if dt.nil?
    dt.to_time.utc.iso8601
  end

  def self.solr_dates(dts)
    dts.map { |dt| solr_date(dt) }
  end

  class << self
    alias_method :file_name, :file_name_for
  end

end
