defmodule Level.MarkdownTest do
  use Level.DataCase, async: true

  alias Level.Markdown
  alias Level.Schemas.Space

  describe "to_html/2" do
    test "transforms markdown to HTML" do
      {:ok, result, _} = Markdown.to_html("# Title")
      assert result == "<h1>Title</h1>"
    end

    test "scrubs script tags" do
      {:ok, result, _} = Markdown.to_html("<h1>Hello <script>World!</script></h1>")
      assert result == "<h1>Hello World!</h1>"
    end

    test "escapes code in code blocks" do
      markdown = """
      ```
      <iframe></iframe>
      ```
      """

      {:ok, result, _} = Markdown.to_html(markdown)
      assert result == "<pre><code class=\"\">&lt;iframe&gt;&lt;/iframe&gt;</code></pre>"
    end

    test "makes all line breaks significant" do
      {:ok, result, _} = Markdown.to_html("Hello\nWorld")
      assert result == "<p>Hello<br/>World</p>"
    end

    test "auto-hyperlinks urls" do
      {:ok, result, _} = Markdown.to_html("Look at https://level.app")

      assert result ==
               ~s(<p><span>Look at <a href="https://level.app">https://level.app</a></span></p>)
    end

    test "does not convert urls to links inside code blocks" do
      markdown = """
      ```
      https://level.app
      ```
      """

      {:ok, result, _} = Markdown.to_html(markdown)

      assert result == ~s(<pre><code class="">https://level.app</code></pre>)
    end

    test "does not convert urls to links inside other links" do
      markdown = """
      [https://level.app](https://google.com)
      """

      {:ok, result, _} = Markdown.to_html(markdown)

      assert result == ~s(<p><a href="https://google.com">https://level.app</a></p>)
    end

    test "highlights mentions" do
      {:ok, result, _} = Markdown.to_html("Hey @derrick")
      assert result == ~s(<p><span>Hey <span class="user-mention">@derrick</span></span></p>)
    end

    test "highlights back-to-back mentions" do
      {:ok, result, _} = Markdown.to_html("Hey @derrick @tiffany")

      assert result ==
               ~s(<p><span>Hey <span class="user-mention">@derrick</span> <span class="user-mention">@tiffany</span></span></p>)
    end

    test "highlights channels only when no space context is given" do
      {:ok, result, _} = Markdown.to_html("Look at #everyone")

      assert result == ~s(<p><span>Look at <span class="tagged-group">#everyone</span></span></p>)
    end

    test "relative links to channels when space context is given" do
      {:ok, result, _} = Markdown.to_html("Look at #everyone", %{space: %Space{slug: "foo"}})

      assert result ==
               ~s(<p><span>Look at <a href="/foo/channels/everyone" class="tagged-group">#everyone</a></span></p>)
    end

    test "absolute links to channels when absolute is true" do
      {:ok, result, _} =
        Markdown.to_html("Look at #everyone", %{space: %Space{slug: "foo"}, absolute: true})

      assert result ==
               ~s(<p><span>Look at <a href="http://level.test:4001/foo/channels/everyone" class="tagged-group">#everyone</a></span></p>)
    end

    test "relative links to users when space context is given" do
      {:ok, result, _} = Markdown.to_html("Hey @derrick", %{space: %Space{slug: "foo"}})

      assert result ==
               ~s(<p><span>Hey <a href="/foo/users/derrick" class="user-mention">@derrick</a></span></p>)
    end

    test "absolute links to users when absolute is true" do
      {:ok, result, _} =
        Markdown.to_html("Look at @john", %{space: %Space{slug: "foo"}, absolute: true})

      assert result ==
               ~s(<p><span>Look at <a href="http://level.test:4001/foo/users/john" class="user-mention">@john</a></span></p>)
    end

    test "strips leading hashtags" do
      {:ok, result, _} = Markdown.to_html("#devs #marketing Hey!")
      assert result == ~s(<p>Hey!</p>)
    end

    test "does not mangle hashs in URLs" do
      {:ok, result, _} = Markdown.to_html("Here: https://level.app/#stuff")

      assert result ==
               ~s(<p><span>Here: <a href=\"https://level.app/#stuff\">https://level.app/#stuff</a></span></p>)
    end
  end
end
