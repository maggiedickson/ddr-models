require "resque"

module Ddr::Managers
  class DerivativesManager < Manager
    extend Deprecation

    SCHEDULE_LATER = :later
    SCHEDULE_NOW = :now
    SCHEDULES = [ SCHEDULE_LATER, SCHEDULE_NOW ]

    ACTION_DELETE = "delete"
    ACTION_GENERATE = "generate"

    def update_derivatives(schedule=SCHEDULE_LATER)
      raise ArgumentError, "Must be one of #{SCHEDULES}" unless SCHEDULES.include?(schedule)
      Ddr::Derivatives::DERIVATIVES.values.each do |derivative|
        if Ddr::Derivatives.update_derivatives.include?(derivative.name)
          # Need to update derivative if object has a datastream for this type of derivative and
          # either (or both) of the following conditions are true:
          # - object already has content in the derivative's datastream (need to delete or replace it)
          # - the derivative can be generated for this object
          if object.datastreams.include?(derivative.datastream) &&
             (object.datastreams[derivative.datastream].has_content? || generatable?(derivative))
            schedule == SCHEDULE_NOW ? update_derivative(derivative) : Resque.enqueue(DerivativeJob, object.pid, derivative.name)
          end
        end
      end
    end

    def update_derivative(derivative)
      raise ArgumentError, "This object does not have a datastream for #{derivative.name} derivatives" unless
        object.datastreams.include?(derivative.datastream)
      if generatable? derivative
        generate_derivative derivative
      else
        # Delete existing derivative (if there is one) if that type of derivative is no longer
        # applicable to the object
        if object.datastreams[derivative.datastream].has_content?
          delete_derivative derivative
        end
      end
    end

    def generate_derivative!(derivative)
      tempdir_path = File.join(Dir.tmpdir, Dir::Tmpname.make_tmpname('',nil))
      begin
        tempdir = FileUtils.mkdir(tempdir_path).first
        generator_source_path = source_datastream.external? ? source_datastream.file_path
                                                            : create_source_file(source_datastream,tempdir)
        generator_output_path = File.new(File.join(tempdir, "output.out"), 'wb').path
        exitstatus = derivative.generator.new(generator_source_path, generator_output_path, derivative.options).generate
        if exitstatus == 0
          generator_output = File.open(generator_output_path, 'rb')
          object.reload if object.persisted?
          object.add_file generator_output, derivative.datastream, mime_type: derivative.generator.output_mime_type
          object.save!
        else
          raise Ddr::Models::DerivativeGenerationFailure,
                "Failure generating #{derivative.name} for #{object.pid}"
        end
        generator_output.close unless generator_output.closed?
      ensure
        FileUtils.remove_dir(tempdir_path) if File.exist?(tempdir_path)
      end
    end

    alias_method :generate_derivative, :generate_derivative!

    def delete_derivative!(derivative)
      File.unlink *object.datastreams[derivative.datastream].file_paths if
        object.datastreams[derivative.datastream].external?
      object.datastreams[derivative.datastream].delete
      object.save!
    end

    alias_method :delete_derivative, :delete_derivative!

    def source_datastream
      @source_datastream ||= object.has_intermediate_file? ? object.datastreams[Ddr::Datastreams::INTERMEDIATE_FILE]
                                                           : object.datastreams[Ddr::Datastreams::CONTENT]
    end

    class DerivativeJob
      @queue = :derivatives
      def self.perform(pid, derivative_name)
        object = ActiveFedora::Base.find(pid)
        derivative = Ddr::Derivatives::DERIVATIVES[derivative_name.to_sym]
        object.derivatives.update_derivative(derivative)
      end
    end

    private

    def create_source_file(datastream, dir)
      generator_source = File.new(File.join(dir, "source"), "wb")
      source_content = datastream.content
      generator_source.write(source_content)
      generator_source.close
      generator_source
    end

    def generatable?(derivative)
      return false unless object.has_content?
      case derivative.name
      when :multires_image
        object.content_type == "image/tiff" || object.content_type == "image/jpeg"
      when :thumbnail
        object.image?
      else
        false
      end
    end

  end
end
