class Page < ApplicationRecord
  include Leafable

  has_rich_text :body

  def searchable_content
    ERB::Util.html_escape(body.to_plain_text)
  end

  def html_preview
    body.to_s
  end

  def markable
    body.present? ? body.to_s : ""
  end
end
