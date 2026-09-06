require "application_system_test_case"
require "base64"

class EditPageTest < ApplicationSystemTestCase
  setup do
    sign_in "kevin@example.com"
  end

  test "edit page" do
    visit edit_book_page_url(books(:handbook), leaves(:welcome_page))
    assert_selector "lexxy-editor"

    fill_lexxy_editor "page[body]", with: "<p>Welcome to the handbook! This is the <strong>first</strong> page.</p>"

    click_button "Save"

    assert_selector ".lexxy-content", text: "Welcome to the handbook! This is the first page."
    assert_selector ".lexxy-content strong", text: "first"
  end

  test "create bulleted and numbered lists" do
    visit edit_book_page_url(books(:handbook), leaves(:welcome_page))
    assert_selector "lexxy-editor"

    fill_lexxy_editor "page[body]", with: "<p>List demo</p>"
    execute_script "document.querySelector('lexxy-editor').selection.placeCursorAtTheEnd()"

    find("button[aria-label='Show more toolbar buttons']").click
    find("button[title='Bullet list']").click
    find(".lexxy-editor__content").send_keys "First bullet", :enter, "Second bullet", :enter, :enter
    find("button[aria-label='Show more toolbar buttons']").click
    find("button[title='Numbered list']").click
    find(".lexxy-editor__content").send_keys "First step", :enter, "Second step"

    click_button "Save"

    assert_selector ".lexxy-content ul li", text: "First bullet"
    assert_selector ".lexxy-content ul li", text: "Second bullet"
    assert_selector ".lexxy-content ol li", text: "First step"
    assert_selector ".lexxy-content ol li", text: "Second step"
  end

  test "preserves Google Docs formatting when pasting" do
    visit edit_book_page_path(books(:handbook), leaves(:welcome_page))
    assert_selector "lexxy-editor"

    fill_lexxy_editor "page[body]", with: ""
    paste_into_lexxy_editor(
      plain_text: "Bold Italic Underlined Struck",
      html: <<~HTML
        <meta charset="utf-8">
        <style>
          .docs-bold { font-weight: 700 }
          .docs-italic { font-style: italic }
          .docs-underlined { text-decoration: underline }
          .docs-struck { text-decoration: line-through }
        </style>
        <b id="docs-internal-guid-test" style="font-weight: normal">
          <p>
            <span class="docs-bold">Bold</span>
            <span class="docs-italic">Italic</span>
            <span class="docs-underlined">Underlined</span>
            <span class="docs-struck">Struck</span>
          </p>
        </b>
      HTML
    )

    click_button "Save"
    assert_selector "#leafable-editor.clean"

    assert_selector ".lexxy-editor__content strong", text: "Bold"
    assert_selector ".lexxy-editor__content em", text: "Italic"
    assert_selector ".lexxy-editor__content .lexxy-content__underline", text: "Underlined"
    assert_selector ".lexxy-editor__content .lexxy-content__strikethrough", text: "Struck"

    visit book_page_path(books(:handbook), leaves(:welcome_page))
    assert_selector ".lexxy-content strong", text: "Bold"
    assert_selector ".lexxy-content em", text: "Italic"
    assert_selector ".lexxy-content u", text: "Underlined"
    assert_selector ".lexxy-content s", text: "Struck"
  end

  test "does not duplicate Google Docs paragraph spacing when pasting" do
    visit edit_book_page_path(books(:handbook), leaves(:welcome_page))
    assert_selector "lexxy-editor"

    fill_lexxy_editor "page[body]", with: ""
    paste_into_lexxy_editor(
      plain_text: "One\n\nTwo\n\nThree",
      html: <<~HTML
        <meta charset="utf-8">
        <b id="docs-internal-guid-spacing" style="font-weight: normal">
          <p><span>One</span></p>
          <br>
          <p><span>Two</span></p>
          <br>
          <p><span>Three</span></p>
        </b>
      HTML
    )

    assert_selector ".lexxy-editor__content > p", count: 3

    click_button "Save"
    assert_selector "#leafable-editor.clean"
    visit book_page_path(books(:handbook), leaves(:welcome_page))

    assert_selector ".lexxy-content > p", count: 3
  end

  test "uploads images pasted from Google Docs" do
    visit edit_book_page_path(books(:handbook), leaves(:welcome_page))
    assert_selector "lexxy-editor"

    image_data = Base64.strict_encode64 Rails.root.join("public/app-icon-192.png").binread
    fill_lexxy_editor "page[body]", with: ""
    paste_into_lexxy_editor(
      plain_text: "",
      html: <<~HTML
        <meta charset="utf-8">
        <b id="docs-internal-guid-image" style="font-weight: normal">
          <p>
            <span style="font-size:11pt;font-family:Inter,sans-serif;color:#000000;background-color:transparent;font-weight:400;font-style:normal;text-decoration:none;white-space:pre-wrap;">
              <img src="data:image/png;base64,#{image_data}" width="192" height="192" style="border:none;">
            </span>
          </p>
        </b>
      HTML
    )

    assert_selector ".lexxy-editor__content figure.attachment[data-content-type='image/png']", wait: 10
    assert_no_selector ".lexxy-editor__content img[src^='data:image']"

    click_button "Save"
    assert_selector "#leafable-editor.clean"
    visit book_page_path(books(:handbook), leaves(:welcome_page))

    assert_selector ".lexxy-content figure.attachment--preview img"
    assert_no_selector ".lexxy-content img[src^='data:image']"
  end
end
