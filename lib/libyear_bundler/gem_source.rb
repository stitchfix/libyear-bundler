require 'libyear_bundler/gem_source/base'
require 'libyear_bundler/gem_source/http_connection'
require 'libyear_bundler/gem_source/rubygems'
require 'libyear_bundler/gem_source/github_packages'
require 'libyear_bundler/gem_source/artifactory'
require 'libyear_bundler/gem_source/unsupported'

module LibyearBundler
  module GemSource
    # Provides a gem source adapter for the given `source_url`.
    #
    # @param source_url [String]
    # @return [Base] a gem source adapter
    def self.for(source_url)
      case source_url
      when %r{\Ahttps://rubygems\.pkg\.github\.com/}
        GithubPackages.new(source_url)
      when 'https://rubygems.org/'
        Rubygems.new
      when %r{\Ahttps?://[^/]+\.jfrog\.io/}
        Artifactory.new(source_url)
      else
        Unsupported.new(source_url)
      end
    end
  end
end
