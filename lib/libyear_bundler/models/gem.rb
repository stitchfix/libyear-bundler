require 'libyear_bundler/gem_source'

module LibyearBundler
  module Models
    # Logic and information pertaining to the installed and newest versions of
    # a gem
    class Gem
      def initialize(name, installed_version, newest_version, release_date_cache, source:)
        unless release_date_cache.nil? || release_date_cache.is_a?(ReleaseDateCache)
          raise TypeError, 'Invalid release_date_cache'
        end
        @name = name
        @installed_version = installed_version
        @newest_version = newest_version
        @release_date_cache = release_date_cache
        @source = source
      end

      def installed_version
        ::Gem::Version.new(@installed_version)
      end

      def installed_version_release_date
        fetch_release_date(installed_version)
      end

      def installed_version_sequence_index
        versions_sequence.index(installed_version.to_s)
      end

      def libyears
        ::LibyearBundler::Calculators::Libyear.calculate(
          installed_version_release_date,
          newest_version_release_date
        )
      end

      def name
        @name
      end

      def newest_version
        ::Gem::Version.new(@newest_version)
      end

      def newest_version_sequence_index
        versions_sequence.index(newest_version.to_s)
      end

      def newest_version_release_date
        fetch_release_date(newest_version)
      end

      def version_number_delta
        ::LibyearBundler::Calculators::VersionNumberDelta.calculate(
          installed_version,
          newest_version
        )
      end

      def version_sequence_delta
        ::LibyearBundler::Calculators::VersionSequenceDelta.calculate(
          installed_version_sequence_index,
          newest_version_sequence_index
        )
      end

      private

      def fetch_release_date(version)
        if @release_date_cache.nil?
          @source.release_date(name, version)
        else
          @release_date_cache.fetch(name, version) { @source.release_date(name, version) }
        end
      end

      def versions_sequence
        @_versions_sequence ||= @source.versions_sequence(name)
      end
    end
  end
end
