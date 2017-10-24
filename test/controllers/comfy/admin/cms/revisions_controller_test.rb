require_relative '../../../../test_helper'

class Comfy::Admin::Cms::RevisionsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @site     = comfy_cms_sites(:default)
    @layout   = comfy_cms_layouts(:default)
    @page     = comfy_cms_pages(:default)
    @snippet  = comfy_cms_snippets(:default)
  end

  def test_get_index_for_layouts
    r :get, comfy_admin_cms_site_layout_revisions_path(site_id: @site, layout_id: @layout)
    assert_response :redirect
    assert_redirected_to action: :show, id: comfy_cms_revisions(:layout)
  end

  def test_get_index_for_pages
    r :get, comfy_admin_cms_site_page_revisions_path(site_id: @site, page_id: @page)
    assert_response :redirect
    assert_redirected_to action: :show, id: comfy_cms_revisions(:page)
  end

  def test_get_index_for_snippets
    r :get, comfy_admin_cms_site_snippet_revisions_path(site_id: @site, snippet_id: @snippet)
    assert_response :redirect
    assert_redirected_to action: :show, id: comfy_cms_revisions(:snippet)
  end

  def test_get_index_for_snippets_with_no_revisions
    Comfy::Cms::Revision.delete_all
    r :get, comfy_admin_cms_site_snippet_revisions_path(site_id: @site, snippet_id: @snippet)
    assert_response :redirect
    assert_redirected_to action: :show, id: 0
  end

  def test_get_show_for_layout
    r :get, comfy_admin_cms_site_layout_revision_path(
      site_id:    @site,
      layout_id:  @layout,
      id:         comfy_cms_revisions(:layout))
    assert_response :success
    assert assigns(:record)
    assert assigns(:revision)
    assert assigns(:record).is_a?(Comfy::Cms::Layout)
    assert_template :show
  end

  def test_get_show_for_page
    r :get, comfy_admin_cms_site_page_revision_path(
      site_id:  @site,
      page_id:  @page,
      id:       comfy_cms_revisions(:page))
    assert_response :success
    assert assigns(:record)
    assert assigns(:revision)
    assert assigns(:record).is_a?(Comfy::Cms::Page)
    assert_template :show
  end

  def test_get_show_for_snippet
    r :get, comfy_admin_cms_site_snippet_revision_path(
      site_id:    @site,
      snippet_id: @snippet,
      id:         comfy_cms_revisions(:snippet))
    assert_response :success
    assert assigns(:record)
    assert assigns(:revision)
    assert assigns(:record).is_a?(Comfy::Cms::Snippet)
    assert_template :show
  end

  def test_get_show_for_bad_type
    r :get, comfy_admin_cms_site_layout_revision_path(
      site_id:    @site,
      layout_id:  'invalid',
      id:         comfy_cms_revisions(:layout))
    assert_response :redirect
    assert_redirected_to comfy_admin_cms_path
    assert_equal 'Record Not Found', flash[:danger]
  end

  def test_get_show_for_layout_failure
    r :get, comfy_admin_cms_site_layout_revision_path(
      site_id:    @site,
      layout_id:  @layout,
      id:         'invalid')
    assert_response :redirect
    assert assigns(:record)
    assert_redirected_to edit_comfy_admin_cms_site_layout_path(@site, assigns(:record))
    assert_equal 'Revision Not Found', flash[:danger]
  end

  def test_get_show_for_page_failure
    r :get, comfy_admin_cms_site_page_revision_path(
      site_id: @site,
      page_id: @page,
      id:     'invalid')
    assert_response :redirect
    assert assigns(:record)
    assert_redirected_to edit_comfy_admin_cms_site_page_path(@site, assigns(:record))
    assert_equal 'Revision Not Found', flash[:danger]
  end

  def test_get_show_for_snippet_failure
    r :get, comfy_admin_cms_site_snippet_revision_path(
      site_id:    @site,
      snippet_id: @snippet,
      id:         'invalid')
    assert_response :redirect
    assert assigns(:record)
    assert_redirected_to edit_comfy_admin_cms_site_snippet_path(@site, assigns(:record))
    assert_equal 'Revision Not Found', flash[:danger]
  end

  def test_revert_for_layout
    assert_difference -> {@layout.revisions.count} do
      r :patch, revert_comfy_admin_cms_site_layout_revision_path(
        site_id:    @site,
        layout_id:  @layout,
        id:         comfy_cms_revisions(:layout)
      )
      assert_response :redirect
      assert_redirected_to edit_comfy_admin_cms_site_layout_path(@site, @layout)
      assert_equal 'Content Reverted', flash[:success]

      @layout.reload
      assert_equal 'revision {{cms:fragment content}}', @layout.content
      assert_equal 'revision css', @layout.css
      assert_equal 'revision js', @layout.js
    end
  end

  def test_revert_for_page
    assert_difference -> {@page.revisions.count} do
      r :patch, revert_comfy_admin_cms_site_page_revision_path(
        site_id:  @site,
        page_id:  @page,
        id:       comfy_cms_revisions(:page)
      )
      assert_response :redirect
      assert_redirected_to edit_comfy_admin_cms_site_page_path(@site, @page)
      assert_equal 'Content Reverted', flash[:success]

      @page.reload

      date_content = comfy_cms_fragments(:datetime).datetime
      assert_equal [
        {identifier: "boolean",   format: "boolean",  content: true},
        {identifier: "file",      format: "file",     content: []},
        {identifier: "datetime",  format: "datetime", content: date_content},
        {identifier: "content",   format: "text",     content: "old content"},
        {identifier: "title",     format: "text",     content: "old title"}
      ], @page.fragments_attributes

      flunk "not restoring non-text stuff correctly"
    end
  end

  def test_revert_for_snippet
    assert_difference -> {@snippet.revisions.count} do
      r :patch, revert_comfy_admin_cms_site_snippet_revision_path(
        site_id:    @site,
        snippet_id: @snippet,
        id:         comfy_cms_revisions(:snippet)
      )
      assert_response :redirect
      assert_redirected_to edit_comfy_admin_cms_site_snippet_path(@site, @snippet)
      assert_equal 'Content Reverted', flash[:success]

      @snippet.reload
      assert_equal 'revision content', @snippet.content
    end
  end
end
