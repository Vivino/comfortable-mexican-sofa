# frozen_string_literal: true

module Comfy
  module CmsHelper

    def url_for_cms(blob)
      if Rails.env.test?
        Rails.application.routes.url_helpers.url_for(blob)
      end

      if blob.is_a?(ActiveStorage::Variant)
        return Rails.application.routes.url_helpers.rails_public_blob_url(blob.blob)
      end

      Rails.application.routes.url_helpers.rails_public_blob_url(blob)
    end

    # Raw content of a page fragment. This is how you get content from unrenderable
    # tags like {{cms:fragment meta, render: false}}
    # Example:
    #   cms_fragment_content(:left_column, CmsPage.first)
    #   cms_fragment_content(:left_column) # if @cms_page is present
    def cms_fragment_content(identifier, page = @cms_page)
      frag = page&.fragments&.detect { |f| f.identifier == identifier.to_s }
      return "" unless frag
      case frag.tag
      when "date", "datetime"
        frag.datetime
      when "checkbox"
        frag.boolean
      when "file", "files"
        frag.attachments
      else
        frag.content
      end
    end

    # Same as cms_fragment_content but with cms tags expanded and rendered. Use
    # it only if you know you got more stuff in the fragment content other than
    # text because this is a potentially expensive call.
    def cms_fragment_render(identifier, page = @cms_page)
      node = page.fragment_nodes.detect { |n| n.identifier == identifier.to_s }
      return "" unless node
      node.renderable = true
      render inline: page.render([node])
    end

    # Raw content of a snippet.
    # Example:
    #   cms_snippet_content(:my_snippet)
    def cms_snippet_content(identifier, cms_site = @cms_site)
      cms_site ||= cms_site_detect
      snippet = cms_site&.snippets&.find_by_identifier(identifier)
      return "" unless snippet
      snippet.content
    end

    # Same as cms_snippet_content but cms tags will be expanded. Note that there
    # is no page context, so snippet cannot contain fragment tags.
    def cms_snippet_render(identifier, cms_site = @cms_site)
      cms_site ||= cms_site_detect
      snippet = cms_site&.snippets&.find_by_identifier(identifier)
      return "" unless snippet
      r = ComfortableMexicanSofa::Content::Renderer.new(snippet)
      render inline: r.render(r.nodes(r.tokenize(snippet.content)))
    end

    def cms_site_detect
      host = request.host_with_port.downcase
      path = request.fullpath
      Comfy::Cms::Site.find_site(host, path)
    end

    # Wrapper to deal with Kaminari vs WillPaginate
    def comfy_paginate(collection)
      return unless collection
      if defined?(WillPaginate)
        will_paginate collection
      elsif defined?(Kaminari)
        paginate collection, theme: "comfy"
      end
    end

  end
end
