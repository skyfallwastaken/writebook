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
end
