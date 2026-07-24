# frozen_string_literal: true

# cspell:disable
require "jekyll"
require "nokogiri"
require "json"
require "open3"
require "pathname"
require "digest"

require_relative "version"

module Jekyll
  # module Jekyll::ShikiCodeBlock
  module Shiki
    def self.resolve_shiki_bundle_path(site)
      shiki_config = site.config["shiki"]
      raise "Shiki highlight failed: Shiki config not found in jekyll config" unless shiki_config

      bundle_path = shiki_config["bundle_path"]
      raise "Shiki highlight failed: Required shiki bundle path." unless bundle_path

      File.join(site.source, bundle_path)
    end

    def self.shiki_highlight(code, lang, site)
      script_path = resolve_shiki_bundle_path(site)

      cache_key = Digest::SHA256.hexdigest("#{lang}::#{code}")
      Jekyll::Cache.new("ShikiCodeBlock").getset(cache_key) do
        input = JSON.generate({ code: code, lang: lang }.compact)
        stdout, stderr, status = Open3.capture3("node", script_path, stdin_data: input)
        raise "Shiki highlight failed: #{stderr}" unless status.success?

        stdout
      end
    end

    def self.create_wrapper(lan, code, site)
      lang = lan.capitalize
      highlighted_code = shiki_highlight(code, lan, site)
      <<~HTML
        <div class="shiki_code" data-shiki-highlighter>
          <div class="code_head">
            <span>#{lan}</span>
            <button type="button" aria-label="Highlight-#{lang}" data-copy-btn></button>
          </div>
          #{highlighted_code}
        </div>
      HTML
    end

    def self.replace_elements(node, site)
      code_el = node.at_css('> code[class^="language-"]')
      return unless code_el

      code = code_el.text
      lang = code_el["class"]
             &.split
             &.find { |class_name| class_name.start_with?("language-") }
             &.delete_prefix("language-")
      fragment = Nokogiri::HTML::DocumentFragment.parse(create_wrapper(lang, code, site))
      node.replace(fragment)
    end

    def self.full_document?(html_content)
      html_content.match?(/\A\s*(<!doctype\s+html|<html\b)/i)
    end

    def self.transform_html(html_content, site)
      doc = if full_document?(html_content)
              Nokogiri::HTML.parse(html_content)
            else
              Nokogiri::HTML::DocumentFragment.parse(html_content)
            end
      elements = doc.css("pre").select { |pre| pre.at_css('> code[class^="language-"]') }
      return html_content if elements.empty?

      elements.each { |node| replace_elements(node, site) }
      doc.to_html
    end
  end
end

Jekyll::Hooks.register :pages, :post_render do |page|
  next unless page.output_ext == ".html"

  page.output = Jekyll::Shiki.transform_html(page.output, page.site)
end

Jekyll::Hooks.register :documents, :post_render do |document|
  next unless document.output_ext == ".html"

  document.output = Jekyll::Shiki.transform_html(document.output, document.site)
end
