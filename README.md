<!-- markdownlint-disable MD033 -->
<!-- markdownlint-disable MD041 -->
<p align="center">
<img src="https://susee.phothin.dev/logo/rubygems_logo.png" width="160" height="160" alt="rubygems" style="border-radius:50%" />
</p>
<h1 align="center">Jekyll::Shiki</h1>

## Overview

Jekyll plugin for [Shiki JS](https://shiki.style/), that bridges the Ruby-based Jekyll environment with the Node.js Shiki ecosystem.

## Installation and Usage

### Installation

The jekyll-shiki gem requires Ruby version `>= 3.3.0` and `Jekyll ~> 4.4`.

- **Add the Gem**

  Add the gem to your project's `Gemfile`:

  ```ruby
  group :jekyll_plugins do
  # other jekyll plugins
  gem "jekyll-shiki"
  end
  ```

  Alternatively, execute the following command:

  ```sh
  bundle add jekyll-shiki
  ```

- **Install Dependencies**

  Run bundler to install the gem and its requirements (including nokogiri for HTML parsing)

  ```sh
  bundle install
  ```

### Configuration

The plugin requires a specific configuration block in your Jekyll `_config.yml` file to locate the Node.js Shiki implementation.
You must define the shiki key. The most critical sub-key is `shiki.file_path`, which points to the JavaScript file responsible for performing the actual highlighting via the Node.js bridge.

`_config.yml`

```yml
plugins:
  # other jekyll plugins
  - jekyll-shiki
# this is required to run shiki code
shiki:
  # recommended to use .mjs extension to avoid conflict with `type` in `package.json`.
  # Don't use .ts extension
  file_path: shiki/index.mjs
```

### First Build and Latency

Users should be aware that the first build will experience significant latency.

Why the delay occurs:

1. **Process Spawning**: The plugin must initialize the Node.js environment for code blocks.
2. **Cache Generation**: On the first run, every code block must be processed and transformed. Subsequent builds utilize the `Jekyll::Cache` system to skip already-processed blocks.
3. **Dependency Loading**: Shiki JS loads themes and grammars into memory during its first execution.

### Creating shiki highlighter

You can find detail at [Shiki Installation & Usage](https://shiki.style/guide/install).

#### Install Shiki

```sh
npm i shiki
```

#### Example `shiki.file_path` Js file and structure

```js
import { createHighlighter } from "shiki";

// create shiki highlighter
async function shikiHL(code, lang) {
  // Load shiki bundledLanguages as you want
  /** @type {import("shiki").BundledLanguage} */
  const defaultLangs = [
    "js",
    "ts",
    "sh",
    "json",
    "html",
    "css",
    "ruby",
    "md",
    "yaml",
    "yml",
    "bash",
  ];
  const highlighter = await createHighlighter({
    langs: [...defaultLangs, "text"],
    // load shiki bundled themes (light and dark mode)
    themes: ["dark-plus", "light-plus"],
  });
  lang = defaultLangs.includes(lang) ? lang : "text";
  return highlighter.codeToHtml(code, {
    lang: lang,
    // Defined both light and dark mode for correct load from ruby side
    themes: {
      light: "light-plus",
      dark: "dark-plus",
    },
  });
}
// The following structure must required to correct load from ruby side
async function readStdin() {
  const chunks = [];

  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }

  return chunks.join("");
}
if (import.meta.url === new URL(process.argv[1], "file:").href) {
  try {
    const args = await readStdin();
    const { code: c, lang: t } = JSON.parse(args);
    // Replace `shikiHL` to your actual shiki highlighter function name.
    const highlighted = await shikiHL(c, t);
    process.stdout.write(highlighted);
  } catch (error) {
    process.stderr.write(
      `${error instanceof Error ? error.message : String(error)}`,
    );
    process.exit(1);
  }
}
```

### Wrapper HTML Structure

The plugin does not just return the highlighted code from Shiki; it wraps it in a UI-friendly container. The `create_wrapper`method generates a `div` with specific classes and data attributes for styling and functionality.

| Element     | Class/Attribute          | Purpose                                                |
| ----------- | ------------------------ | ------------------------------------------------------ |
| Container   | `div.shiki_code`         | Main wrapper for the code block.                       |
| Hook        | `data-shiki-highlighter` | Attribute for JS or CSS targeting.                     |
| Header      | `div.code_head`          | Contains the language label and copy button.           |
| Label       | `span`                   | Displays the raw language string (e.g., ruby).         |
| Copy Button | `button[data-copy-btn]`  | An empty button intended for clipboard JS integration. |
| Output      | `shiki_highlight`        | The actual HTML returned by the Node.js Shiki process. |

### Generated HTML Template

The structure is defined as a heredoc in Ruby:

```html
<div class="shiki_code" data-shiki-highlighter>
  <div class="code_head">
    <span>#{lan}</span>
    <button type="button" aria-label="Highlight-#{lang}" data-copy-btn></button>
  </div>
  #{highlighted_code}
</div>
```

#### Styles for generated HTML template

Create `scss` file `_codeBlock.scss` with the following code.

You can edit color or whatever but don't edit `shiki` and `shiki span` in dark mode , that are rely to shiki generated code.

```scss
// cspell:disable
$iconCopy: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' stroke='black' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' viewBox='0 0 24 24'%3E%3Crect width='8' height='4' x='8' y='2' rx='1' ry='1'/%3E%3Cpath d='M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2'/%3E%3C/svg%3E");
$iconCopied: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' stroke='black' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' viewBox='0 0 24 24'%3E%3Crect width='8' height='4' x='8' y='2' rx='1' ry='1'/%3E%3Cpath d='M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2'/%3E%3Cpath d='m9 14 2 2 4-4'/%3E%3C/svg%3E");

@mixin iconMask($icon, $color) {
  background-color: $color;
  -webkit-mask-image: $icon;
  mask-image: $icon;
  -webkit-mask-position: 50%;
  mask-position: 50%;
  -webkit-mask-repeat: no-repeat;
  mask-repeat: no-repeat;
  -webkit-mask-size: 20px;
  mask-size: 20px;
}

:root {
  --hr-bg: #ffffff;
  --hr-bg-2: #f3f3f3;
  --hr-lang: #1f1f1f;
  --hr-lang-muted: #616161;
  --hr-border: #e5e5e5;
  --hr-success: #18794e;
}

.dark,
*[data-theme="dark"] {
  --hr-bg: #1e1e1e;
  --hr-bg-2: #252526;
  --hr-lang: #d4d4d4;
  --hr-lang-muted: #cccccc;
  --hr-border: #3c3c3c;
  --hr-success: #3dd68c;
  // don't edit
  .shiki,
  .shiki span {
    color: var(--shiki-dark) !important;
    background-color: var(--shiki-dark-bg) !important;
    /* Optional, if you also want font styles */
    font-style: var(--shiki-dark-font-style) !important;
    font-weight: var(--shiki-dark-font-weight) !important;
    text-decoration: var(--shiki-dark-text-decoration) !important;
  }
}

div.shiki_code {
  position: relative;
  margin: auto;
  width: 100%;
  background-color: var(--hr-bg);
  overflow: hidden;
  transition: background-color 0.5s;
  margin-top: 7px;
  margin-bottom: 7px;
  border-radius: 8px;
  border: 1px solid var(--hr-border);
  box-shadow: 0 4px 14px color-mix(in srgb, var(--hr-border) 10%, transparent);

  @media (max-width: 640px) {
    border-radius: 8px;
    margin: 16px 0;
  }
}

div.shiki_code > div.code_head {
  display: flex;
  flex-direction: row;
  padding: 0.42rem 1rem;
  align-items: center;
  justify-content: space-between;
  background-color: var(--hr-bg-2);
  border-bottom: 1px solid var(--hr-border);
}
div.shiki_code > div.code_head > span {
  font-size: 0.84rem;
  font-weight: 400;
  letter-spacing: 0.01em;
  -webkit-user-select: none;
  user-select: none;
  color: var(--hr-lang-muted);
  transition:
    color 0.4s,
    opacity 0.4s;
}
div.shiki_code > div.code_head > button {
  position: relative;
  border: none;
  border-radius: 4px;
  width: 20px;
  height: 20px;
  background-color: transparent;
  cursor: pointer;
  transition:
    border-color 0.25s,
    background-color 0.25s,
    opacity 0.25s;

  &:hover {
    background-color: color-mix(in srgb, var(--hr-lang-muted) 10%, transparent);
  }

  &::before {
    content: "";
    position: absolute;
    inset: 0;
    @include iconMask($iconCopy, var(--hr-lang));
    transition: background-color 0.25s;
  }
}
div.shiki_code > div.code_head > button.copied,
div.shiki_code > div.code_head > button:hover.copied {
  &::before {
    @include iconMask($iconCopied, var(--hr-success));
  }
}

div.shiki_code > pre.shiki {
  position: relative;
  z-index: 1;
  margin: 0;
  padding: 12px 0;
  background: transparent;
  overflow-x: auto;
  scrollbar-gutter: stable;
  direction: ltr;
  text-align: left;
  white-space: pre;
  word-spacing: normal;
  word-break: normal;
  word-wrap: normal;
  -moz-tab-size: 4;
  -o-tab-size: 4;
  tab-size: 4;
  -webkit-hyphens: none;
  -moz-hyphens: none;
  -ms-hyphens: none;
  hyphens: none;
}

.shiki_code > pre.shiki > code {
  display: block;
  padding: 0 24px;
  width: fit-content;
  min-width: 100%;
  line-height: 1.65;
  font-size: 0.95rem;
  font-family: var(--font-mono);
  color: var(--hr-lang);
  transition: color 0.5s;
  direction: ltr;
  text-align: left;
  white-space: pre;
  word-spacing: normal;
  word-break: normal;
  word-wrap: normal;
  -moz-tab-size: 4;
  -o-tab-size: 4;
  tab-size: 4;
  -webkit-hyphens: none;
  -moz-hyphens: none;
  -ms-hyphens: none;
  hyphens: none;
}
```

Use in your `sass` entry (like `main.scss`) , make sure your actual `sass` entry and `_codeBlock.scss` are same directory.

```scss
---
---

@use "codeBlock";
```

#### Js for data-copy-btn

You can use following Js code for `data-copy-btn`.

```js
function codeBlockCopy() {
  const codeBlocks = document.querySelectorAll("[data-shiki-highlighter]");
  if (!codeBlocks.length) return;

  function fallbackCopy(text) {
    const textarea = $.document.createElement("textarea");
    textarea.value = text;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "fixed";
    textarea.style.opacity = "0";
    document.body.appendChild(textarea);
    textarea.select();

    let success = false;
    try {
      success = document.execCommand("copy");
    } catch (e) {
      success = false;
    }

    $.document.body.removeChild(textarea);
    return success;
  }

  async function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      try {
        await navigator.clipboard.writeText(text);
        return true;
      } catch (e) {
        return fallbackCopy(text);
      }
    }
    return fallbackCopy(text);
  }

  codeBlocks.forEach((block) => {
    const copyBtn = block.querySelector("[data-copy-btn]");
    const code = block.querySelector("pre code");
    if (!copyBtn || !code) return;

    copyBtn.addEventListener("click", async () => {
      const text = code.textContent;
      const success = await copyText(text);
      if (success) {
        copyBtn.classList.add("copied");

        setTimeout(() => {
          copyBtn.classList.remove("copied");
        }, 1000);
      }
    });
  });
}
codeBlockCopy();
```

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/phothinmg/jekyll-shiki>. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/phothinmg/jekyll-shiki/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Jekyll::Shiki project's codebases, issue trackers, chat rooms, and mailing lists is expected to follow the [code of conduct](https://github.com/phothinmg/jekyll-shiki/blob/master/CODE_OF_CONDUCT.md).
