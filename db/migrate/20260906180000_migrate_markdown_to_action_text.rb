class MigrateMarkdownToActionText < ActiveRecord::Migration[8.0]
  class LegacyMarkdown < ActiveRecord::Base
    self.table_name = "action_text_markdowns"
  end

  def up
    require "uri"

    create_table :action_text_rich_texts do |t|
      t.string :name, null: false
      t.text :body
      t.references :record, null: false, polymorphic: true, index: false
      t.timestamps

      t.index [ :record_type, :record_id, :name ],
        name: :index_action_text_rich_texts_uniqueness, unique: true
    end

    require "markdown_renderer"
    ActionText::RichText.reset_column_information

    LegacyMarkdown.find_each do |markdown|
      html = MarkdownRenderer.build.render(markdown.content)
      html = replace_uploads(html, markdown)

      ActionText::RichText.create!(
        name: markdown.name,
        body: html,
        record_type: markdown.record_type,
        record_id: markdown.record_id,
        created_at: markdown.created_at,
        updated_at: markdown.updated_at
      )
    end

    ActiveStorage::Attachment.where(record_type: "ActionText::Markdown").delete_all
    drop_table :action_text_markdowns
    remove_column :active_storage_attachments, :slug
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Action Text HTML cannot be converted back to the original Markdown"
  end

  private
    def replace_uploads(html, markdown)
      fragment = Nokogiri::HTML5.fragment(html)
      uploads = ActiveStorage::Attachment.where(
        record_type: "ActionText::Markdown", record_id: markdown.id, name: "uploads"
      ).includes(:blob).index_by(&:slug)

      fragment.css("img[src]").each do |image|
        upload = uploads[File.basename(URI.parse(image["src"]).path)]
        next unless upload

        attachment = ActionText::Attachment.from_attachable(upload.blob)
        replaceable = image.parent.name == "a" ? image.parent : image
        replaceable.replace(attachment.to_html)
      rescue URI::InvalidURIError
        next
      end

      fragment.to_html
    end
end
