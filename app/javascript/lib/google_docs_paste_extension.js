import * as Lexxy from "lexxy"

const {
  COMMAND_PRIORITY_HIGH,
  PASTE_COMMAND,
  PASTE_TAG
} = Lexxy.Lexical

const FORMATTING_PROPERTIES = [
  "font-style",
  "font-weight",
  "text-decoration",
  "text-decoration-line"
]

class GoogleDocsPasteExtension extends Lexxy.Extension {
  get enabled() {
    return this.editorElement.supportsRichText
  }

  get lexicalExtension() {
    const editorElement = this.editorElement

    return this.defineExtension({
      name: "writebook/google-docs-paste",
      register(editor) {
        return editor.registerCommand(PASTE_COMMAND, (event) => {
          const html = event.clipboardData?.getData("text/html")
          if (!html) return false

          const doc = new DOMParser().parseFromString(html, "text/html")
          if (!doc.querySelector("[id^='docs-internal-guid-']")) return false

          preserveGoogleDocsFormatting(doc)
          event.preventDefault()
          editorElement.contents.insertDOM(doc, { tag: PASTE_TAG })
          return true
        }, COMMAND_PRIORITY_HIGH)
      }
    })
  }
}

function preserveGoogleDocsFormatting(doc) {
  stripImageWrapperFormatting(doc)
  removeRedundantBlankSeparators(doc)

  const rules = formattingRules(doc)

  for (const element of doc.body.querySelectorAll("*")) {
    const styles = declaredFormatting(element, rules)
    const tags = []

    if (isBold(styles.get("font-weight"))) tags.push("strong")
    if (isItalic(styles.get("font-style"))) tags.push("em")

    const decoration = `${styles.get("text-decoration") || ""} ${styles.get("text-decoration-line") || ""}`
    if (decoration.includes("underline")) tags.push("u")
    if (decoration.includes("line-through")) tags.push("s")

    for (const tag of tags) {
      const wrapper = doc.createElement(tag)
      wrapper.append(...element.childNodes)
      element.append(wrapper)
    }
  }
}

// Google Docs wraps pasted images in spans carrying text-only presentation
// styles. Lexical's span conversion applies those styles to text children and
// drops a non-text image before Lexxy can turn its data URI into an upload.
function stripImageWrapperFormatting(doc) {
  for (const image of doc.querySelectorAll("img")) {
    let wrapper = image.parentElement

    while (wrapper?.tagName === "SPAN" && wrapper.textContent.trim() === "") {
      wrapper.removeAttribute("class")
      wrapper.removeAttribute("style")
      wrapper = wrapper.parentElement
    }
  }
}

// Google Docs represents the blank line separating two paragraphs as both a
// paragraph boundary and a <br> (or occasionally an empty <p>). Lexxy already
// renders the boundary with paragraph spacing, so keeping both doubles the gap.
// Remove one separator from each run; any additional separators still represent
// additional blank lines.
function removeRedundantBlankSeparators(doc) {
  const separators = Array.from(doc.querySelectorAll("br, p")).filter(isBlankSeparator)
  const parents = new Set(separators.map((separator) => separator.parentElement))

  for (const parent of parents) {
    const children = Array.from(parent.children)

    for (let index = 0; index < children.length;) {
      if (!isBlankSeparator(children[index])) {
        index += 1
        continue
      }

      const firstBlank = index
      while (isBlankSeparator(children[index])) index += 1

      if (firstBlank > 0 && index < children.length) {
        children[firstBlank].remove()
      }
    }
  }
}

function isBlankSeparator(element) {
  return element?.tagName === "BR" || isBlankParagraph(element)
}

function isBlankParagraph(element) {
  return element?.tagName === "P"
    && element.textContent.replaceAll("\u00a0", "").trim() === ""
    && !element.querySelector("img, video, audio, iframe, embed, object, table")
}

function formattingRules(doc) {
  return Array.from(doc.querySelectorAll("style")).flatMap((element) => {
    const sheet = new CSSStyleSheet()

    try {
      sheet.replaceSync(element.textContent)
      return Array.from(sheet.cssRules).filter((rule) => rule instanceof CSSStyleRule)
    } catch {
      return []
    }
  })
}

function declaredFormatting(element, rules) {
  const styles = new Map()

  for (const rule of rules) {
    try {
      if (!element.matches(rule.selectorText)) continue
    } catch {
      continue
    }

    for (const property of FORMATTING_PROPERTIES) {
      const value = rule.style.getPropertyValue(property)
      if (value) styles.set(property, value)
    }
  }

  for (const property of FORMATTING_PROPERTIES) {
    const value = element.style.getPropertyValue(property)
    if (value) styles.set(property, value)
  }

  return styles
}

function isBold(value = "") {
  return value === "bold" || value === "bolder" || Number.parseInt(value, 10) >= 600
}

function isItalic(value = "") {
  return value === "italic" || value.startsWith("oblique")
}

Lexxy.configure({
  global: {
    extensions: [ GoogleDocsPasteExtension ]
  }
})
