# frozen_string_literal: true

require_relative "lib/version"

Gem::Specification.new do |spec|
  spec.name = "jekyll-shiki"
  spec.version = Jekyll::Shiki::VERSION
  spec.authors = ["phothinmg"]
  spec.email = ["phothinmg@disroot.org"]

  spec.summary = "Jekyll plugin for Shiki Js"
  spec.homepage = "Put your gem's website or public repo URL here."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"
  spec.metadata["source_code_uri"] = "https://github.com/mmdocs/jekyll-shiki"
  spec.metadata["changelog_uri"] = "https://github.com/mmdocs/jekyll-shiki/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.files = `git ls-files -z`.split("\x0").select do |f|
    f.match(/^(lib|LICENSE|README)/i)
  end
  spec.require_paths = ["lib"]
  spec.add_dependency "jekyll", "~> 4.4"
  spec.add_dependency "nokogiri", ">= 1.19.4"
end
