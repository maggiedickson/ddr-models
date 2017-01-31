require 'rubydora'

module Rubydora
  module RestApiClient

    def add_datastream(options = {})
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      file = query_options.delete(:content)
      content_type = query_options.delete(:content_type) || query_options[:mimeType] || file_content_type(file)
      run_hook :before_add_datastream, :pid => pid, :dsid => dsid, :file => file, :options => options
      # str = file.respond_to?(:read) ? file.read : file
      file.rewind if file.respond_to?(:rewind)
      # ProfileParser.parse_datastream_profile(client[datastream_url(pid, dsid, query_options)].post(str, :content_type => content_type.to_s, :multipart => true))
      ProfileParser.parse_datastream_profile(client[datastream_url(pid, dsid, query_options)].post(file, :content_type => content_type.to_s, :multipart => true))
    rescue Exception => exception
      rescue_with_handler(exception) || raise
    end

    def modify_datastream(options = {})
      query_options = options.dup
      pid = query_options.delete(:pid)
      dsid = query_options.delete(:dsid)
      file = query_options.delete(:content)
      content_type = query_options.delete(:content_type) || query_options[:mimeType] || file_content_type(file)
      rest_client_options = {}
      if file
        rest_client_options[:multipart] = true
        rest_client_options[:content_type] = content_type
      end

      run_hook :before_modify_datastream, :pid => pid, :dsid => dsid, :file => file, :content_type => content_type, :options => options
      #str = file.respond_to?(:read) ? file.read : file
      file.rewind if file.respond_to?(:rewind)
      #ProfileParser.parse_datastream_profile(client[datastream_url(pid, dsid, query_options)].put(str, rest_client_options))
      ProfileParser.parse_datastream_profile(client[datastream_url(pid, dsid, query_options)].put(file, rest_client_options))
    rescue Exception => exception
      rescue_with_handler(exception) || raise
    end

  end
end
