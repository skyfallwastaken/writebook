require "application_system_test_case"

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
end
