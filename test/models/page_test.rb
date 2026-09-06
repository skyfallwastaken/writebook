require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "html preview" do
    page = Page.new(body: "<h1>Hello</h1><p>World!</p>")

    assert_match /<h1>Hello<\/h1>/, page.html_preview
    assert_match /<p>World!<\/p>/, page.html_preview
  end

  test "markable returns rich text HTML" do
    page = Page.new(body: "<h2>Rich text content</h2><p>With <strong>bold</strong> text.</p>")

    assert_includes page.markable, "<h2>Rich text content</h2><p>With <strong>bold</strong> text.</p>"
  end

  test "markable returns empty string when body is empty" do
    page = Page.new(body: "")

    assert_equal "", page.markable
  end

  test "searchable_content re-encodes HTML entities decoded by to_plain_text" do
    page = Page.new(body: "5 < 10 & 10 > 5")

    assert_includes page.searchable_content, "5 &lt; 10 &amp; 10 &gt; 5"
    assert page.searchable_content.html_safe?
  end
end
