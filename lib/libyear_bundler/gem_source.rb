require 'libyear_bundler/gem_source/base'
require 'libyear_bundler/gem_source/rubygems'
require 'libyear_bundler/gem_source/github_packages'
require 'libyear_bundler/gem_source/unsupported'

module LibyearBundler
  module GemSource
    def self.for(source_url, http)
      case source_url
      when %r{\Ahttps://rubygems\.pkg\.github\.com/}
        GithubPackages.new(source_url)
      when 'https://rubygems.org/'
        Rubygems.new(http)
      else
        Unsupported.new(source_url)
      end
    end
  end
end
