module SystemTestHelper
  include ActionView::Helpers::JavaScriptHelper

  def sign_in(email_address, password = "secret123456")
    visit new_session_url

    fill_in "email_address", with: email_address
    fill_in "password", with: password

    click_button "Sign in"
    assert_selector "h2", text: "Handbook", wait: 15
  end

  def fill_lexxy_editor(name, with:)
    execute_script <<~JS
      const editor = document.querySelector("[name='#{name}']")
      editor.value = "#{escape_javascript(with)}"
      editor.dispatchEvent(new CustomEvent("lexxy:change", { bubbles: true }))
    JS
  end

  def paste_into_lexxy_editor(html:, plain_text:)
    execute_script <<~JS
      const editor = document.querySelector("lexxy-editor")
      const clipboard = new DataTransfer()
      clipboard.setData("text/html", #{html.to_json})
      clipboard.setData("text/plain", #{plain_text.to_json})
      editor.selection.placeCursorAtTheEnd()
      editor.querySelector(".lexxy-editor__content").dispatchEvent(
        new ClipboardEvent("paste", { bubbles: true, cancelable: true, clipboardData: clipboard })
      )
    JS
  end
end
