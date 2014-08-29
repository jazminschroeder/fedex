require 'base64'
require 'pathname'

module Fedex
  class GroundManifest
    attr_reader :manifest_data, :filename

    # Initialize Fedex::GroundManifest Object
    # @param [Hash] options
    def initialize(options = {})
      puts options
      @filename = options[:filename]
      @manifest_data = Base64.decode64(options[:manifest][:file])
      save
    end

    def save
      return if manifest_data.nil? || filename.nil?
      full_path = Pathname.new(filename)
      File.open(full_path, 'wb') do |f|
        f.write(manifest_data)
      end
    end
  end
end
