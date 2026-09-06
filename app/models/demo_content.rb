class DemoContent
  class << self
    def create_manual(user)
      book = create_book(user)
      load_markdown_pages(book)
    end

    private
      def create_book(user)
        Book.create(title: "The Writebook Manual", author: "37signals", everyone_access: true).tap do |book|
          with_attachment("writebook-manual.jpg") { |attachment| book.cover.attach(attachment) }
          book.update_access(readers: [], editors: [ user.id ])
        end
      end

      def load_markdown_pages(book)
        pages = {}

        Dir.glob(Rails.root.join("app/assets/markdown/demo/*.md")).each do |fname|
          front_matter = FrontMatterParser::Parser.parse_file(fname)

          if front_matter["class"] == "Section"
            load_section(book, front_matter)
          else
            page = load_markdown_page(book, front_matter)
            attach_images(page)
            pages[page.leaf.slug] = page
          end
        end

        book.leaves.pages.each { |leaf| localize_ref_links(leaf.page, pages) }
      end

      def load_markdown_page(book, front_matter)
        body = MarkdownRenderer.build.render(front_matter.content)
        book.press(Page.new(body: body), title: front_matter["title"]).page
      end

      def load_section(book, front_matter)
        book.press Section.new(body: front_matter.content, theme: front_matter["theme"]), title: front_matter["title"]
      end

      def attach_images(page)
        body = Nokogiri::HTML5.fragment(page.body.body.to_html)

        body.css("img[src^='/u/']").each do |image|
          filename = File.basename(image["src"])
          with_attachment(filename) do |attachment|
            blob = ActiveStorage::Blob.create_and_upload!(**attachment)
            replaceable = image.parent.name == "a" ? image.parent : image
            replaceable.replace(ActionText::Attachment.from_attachable(blob).to_html)
          end
        end

        page.update!(body: body.to_html)
      end

      def localize_ref_links(page, pages)
        body = Nokogiri::HTML5.fragment(page.body.body.to_html)

        body.css("a[href]").each do |link|
          next unless link["href"] =~ %r{\A/\d+/[\w-]+/\d+/([\w-]+)(.*)\z}

          linked_page = pages[$1]
          raise "Invalid reference link: #{link.text}" unless linked_page.present?

          link["href"] = Rails.application.routes.url_helpers.leafable_slug_path(linked_page.leaf, only_path: true) + $2
        end

        page.update!(body: body.to_html)
      end

      def with_attachment(filename)
        File.open(Rails.root.join("app/assets/images/demo/#{filename}")) do |file|
          yield io: file, filename: filename
        end
      end
  end
end
