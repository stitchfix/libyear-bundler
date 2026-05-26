require 'yaml'
require 'libyear_bundler/yaml_loader'

module LibyearBundler
  # A cache of release dates by name and version, for both gems and rubies.
  class ReleaseDateCache
    # @param data [Hash<String,Date>]
    def initialize(data)
      raise TypeError unless data.is_a?(Hash)
      @data = data
    end

    def fetch(name, version)
      key = format('%s-%s', name, version)
      @data[key] ||= yield
    end

    def empty?
      @data.empty?
    end

    def size
      @data.size
    end

    class << self
      def load(path)
        if File.exist?(path)
          new(YAMLLoader.safe_load(File.read(path)))
        else
          new({})
        end
      end
    end

    def save(path)
      content = YAML.dump(@data)
      begin
        File.write(path, content)
      rescue StandardError => e
        warn format('Unable to update cache: %s, %s', path, e.message)
      end
    end
  end
end
