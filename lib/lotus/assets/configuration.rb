require 'pathname'
require 'json'
require 'lotus/utils/string'
require 'lotus/utils/class'
require 'lotus/utils/path_prefix'
require 'lotus/assets/config/sources'

module Lotus
  module Assets
    class Configuration
      DEFAULT_PUBLIC_DIRECTORY = 'public'.freeze
      DEFAULT_MANIFEST         = 'assets.json'.freeze
      DEFAULT_PREFIX           = '/assets'.freeze

      def self.for(base)
        # TODO this implementation is similar to Lotus::Controller::Configuration consider to extract it into Lotus::Utils
        namespace = Utils::String.new(base).namespace
        framework = Utils::Class.load_from_pattern!("(#{namespace}|Lotus)::Assets")
        framework.configuration
      end

      attr_reader :registry

      def initialize
        reset!
      end

      def compile(value = nil)
        if value.nil?
          @compile
        else
          @compile = value
        end
      end

      def digest(value = nil)
        if value.nil?
          @digest
        else
          @digest = value
        end
      end

      def prefix(value = nil)
        if value.nil?
          @prefix
        else
          @prefix = Utils::PathPrefix.new(value)
        end
      end

      def root(value = nil)
        if value.nil?
          @root
        else
          @root = Pathname.new(value).realpath
          sources.root = @root
        end
      end

      def public_directory(value = nil)
        if value.nil?
          @public_directory
        else
          @public_directory = Pathname.new(::File.expand_path(value))
        end
      end

      def manifest(value = nil)
        if value.nil?
          @manifest
        else
          @manifest = value.to_s
        end
      end

      # @api private
      def manifest_path
        public_directory.join(manifest)
      end

      def sources
        @sources ||= Lotus::Assets::Config::Sources.new(root)
      end

      def files
        sources.files
      end

      # @api private
      def find(file)
        @sources.find(file)
      end

      # @api private
      def asset_path(source)
        result = prefix.join(source)
        result = registry.fetch(result.to_s) if digest
        result
      end

      def duplicate
        Configuration.new.tap do |c|
          c.root             = root
          c.prefix           = prefix
          c.compile          = compile
          c.public_directory = public_directory
          c.manifest         = manifest
          c.sources          = sources.dup
        end
      end

      def reset!
        @prefix  = Utils::PathPrefix.new(DEFAULT_PREFIX)
        @compile = false

        root             Dir.pwd
        public_directory root.join(DEFAULT_PUBLIC_DIRECTORY)
        manifest         DEFAULT_MANIFEST
      end

      def load!
        if digest && manifest_path.exist?
          @registry = JSON.load(manifest_path.read)
        end
      end

      protected
      attr_writer :compile
      attr_writer :prefix
      attr_writer :root
      attr_writer :public_directory
      attr_writer :manifest
      attr_writer :sources
    end
  end
end
