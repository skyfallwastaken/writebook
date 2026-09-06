ActiveSupport.on_load(:action_text_content) do
  helper = Class.new.include(ActionText::ContentHelper).new
  ActionText::ContentHelper.allowed_tags = helper.sanitizer_allowed_tags + %w[ details iframe options s summary u ]
  ActionText::ContentHelper.allowed_attributes = helper.sanitizer_allowed_attributes + %w[
    allowfullscreen autoplay controls data-action data-lightbox-target
    data-lightbox-url-value frameborder id loading muted open playsinline reversed
  ]
end
