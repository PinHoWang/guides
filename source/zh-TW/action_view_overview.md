**DO NOT READ THIS FILE IN GITHUB, GUIDES ARE PUBLISHED IN http://rails.ruby.tw.**

Action View 綜覽
================

讀完本篇，您將了解：

* 什麼是 Action View、如何在 Rails 裡使用。
* 如何善用模版，局部頁面與版型。
* Action View 提供的輔助方法、如何自己寫輔助方法。
* 如何使用本地化的 View。
* 如何在 Rails 之外使用 Action View。

--------------------------------------------------------------------------------

什麼是 Action View？
------------------

Action View 與 Action Controller 是 Action Pack 中的兩個主要元件。 在 Rails 裡，網路請求是由 Action Pack 負責處理的。此過程分成處理邏輯的 controller 步驟，及算繪模版的 view 步驟。通常 Action Controller 是與資料庫溝通，根據需求來執行 CRUD 操作。而 Action View 則接著負責編譯出回應。

Action View 模版是由嵌入 HTML 的 Ruby 撰寫而成。為了避免模版充斥混亂的程式碼，Action View 提供了許多輔助方法，用來撰寫表單、日期及字串等。當應用程式成長時，加入自訂的輔助方法也很容易。

NOTE: 部份 Action View 的功能與 Active Record 綁在一起。但這不代表 Action View 依賴於 Action Record。Active View 是個獨立的函式庫，可以和其它的 Ruby 函式庫一起使用。

在 Rails 中使用 Action View
--------------------------

每個 Controller 在 `app/views` 中都會有一個對應的資料夾，裡面包含了該 Controller 的模板檔案。這些檔案用來顯示 Controller 各個動作的結果頁面。

看看 Rails 用 `scaffold` 命令建立新資源時，預設會產生哪些檔案：

```bash
$ bin/rails generate scaffold article
      [...]
      invoke  scaffold_controller
      create    app/controllers/articles_controller.rb
      invoke    erb
      create      app/views/articles
      create      app/views/articles/index.html.erb
      create      app/views/articles/edit.html.erb
      create      app/views/articles/show.html.erb
      create      app/views/articles/new.html.erb
      create      app/views/articles/_form.html.erb
      [...]
```

Rails 的 View 有命名慣例。通常 View 的檔名和 Controller 的動作同名，如上所示。例如 `articles_controller.rb` 的 `index` 動作使用 `app/views/articles` 資料夾中的 `index.html.erb` 這個 View 檔案。回傳給用戶端的完整 HTML 是由這個 ERB 檔案、版型，以及其它引用的局部頁面組成。本篇之後會對這三種 View 做更詳細的介紹。

模版、局部頁面及版型
-----------------

上面有提到過，最終輸出的 HTML 由三種 Rails 元素組成：模版、局部頁面以及版型。底下簡單介紹這三種元素。

### 模版

Action View 的模版有數種不同的寫法。如果模版的副檔名是 `erb` 的話，那麼這個模版是混合 ERB （Ruby 內建）和 HTML。若模版的副檔名是 `.builder`，則是使用了 `Builder::XmlMarkup` 函式庫。

Rails 支援多種模版系統，使用副檔名來做區隔。例如使用 ERB 模版系統的 HTML 檔案，副檔名是 `.html.erb`。

#### ERB

在 ERB 模版裡，Ruby 程式碼會放在 `<% %>` 或是 `<%= %>` 標籤裡。`<% %>` 標籤是用來執行不會回傳任何值的 Ruby 程式碼，例如條件判斷、迴圈或是區塊等等，而 `<%= %>` 標籤則是用來輸出結果。

考慮以下 `names` 迴圈：

```html+erb
<h1>Names of all the people</h1>
<% @people.each do |person| %>
  Name: <%= person.name %><br>
<% end %>
```

迴圈放在普通嵌入標籤（`<% %>`）裡，而需要顯示的 `name` 則是放在會輸出結果的標籤（`<%= %>`）中。注意這不是建議的使用方法，Ruby 一般的輸出函式如 `print` 或是 `puts` 是無法將結果顯示在 ERB 模版裡。所以以下的範例是不正確的：

```html+erb
<%# WRONG %>
Hi, Mr. <% puts "Frodo" %>
```

要去掉開頭或結尾的空白，可以用 `<%-` `-%>` 來取代 `<%` 及 `%>`。

#### Builder

Builder 模版 ERB 的替代方案，比 ERB 需要更多程式設計。在產生 XML 時特別有用。在副檔名為 `.builder` 的模版裡，可以直接使用名為 `xml` 的 `XmlMarkup` 物件。

以下是一些簡單的範例：

```ruby
xml.em("emphasized")
xml.em { xml.b("emph & bold") }
xml.a("A Link", "href" => "http://rubyonrails.org")
xml.target("name" => "compile", "option" => "fast")
```

會產生：

```html
<em>emphasized</em>
<em><b>emph &amp; bold</b></em>
<a href="http://rubyonrails.org">A link</a>
<target option="fast" name="compile" />
```

傳入區塊的方法會被當成一個巢狀 XML 標籤的外層，區塊內容則會嵌套成內層的標籤來處理。見下例：

```ruby
xml.div {
  xml.h1(@person.name)
  xml.p(@person.bio)
}
```

會生成：

```html
<div>
  <h1>David Heinemeier Hansson</h1>
  <p>A product of Danish Design during the Winter of '79...</p>
</div>
```

以下是一個 Basecamp 中實際用到的完整 RSS 範例：

```ruby
xml.rss("version" => "2.0", "xmlns:dc" => "http://purl.org/dc/elements/1.1/") do
  xml.channel do
    xml.title(@feed_title)
    xml.link(@url)
    xml.description "Basecamp: Recent items"
    xml.language "en-us"
    xml.ttl "40"

    for item in @recent_items
      xml.item do
        xml.title(item_title(item))
        xml.description(item_description(item)) if item_description(item)
        xml.pubDate(item_pubDate(item))
        xml.guid(@person.firm.account.url + @recent_items.url(item))
        xml.link(@person.firm.account.url + @recent_items.url(item))
        xml.tag!("dc:creator", item.author_name) if item_has_creator?(item)
      end
    end
  end
end
```

#### 模版快取


Rail 預設會編譯所有的模版來進行算繪。當你修改某個模板後，development 模式下的 Rails 會重新檢查及編譯它。

### 局部頁面

局部頁面模板 - 簡稱局部頁面 - 用來把算繪過程拆成更好管理的小片段的工具。有了局部頁面，可以把某些特定內容的算繪移到單獨的檔案。

#### 局部頁面命名

在 view 檔案中，你要用 `render` 來算繪局部頁面

```erb
<%= render "menu" %>
```

這樣會在呼叫的地方，找到目前資料夾下的 `_meun.html.erb` 檔案來算繪。注意名字開頭的"底線" (_): 局部頁面的命名規則是由底線開頭。用來與一般的 view 區別。但在引用局部頁面時，呼叫的語法不用加上底線。如果要呼叫其它資料夾下的局部頁面也是一樣不加底線：

```erb
<%= render "shared/menu" %>
```

這樣會去找到 `app/views/shared/_menu.html.erb` 檔案來引入。

#### 使用局部頁面來簡化 Views

局部頁面的一個用途是把它拿來當副程式；把細節的部份拆出去，讓你更容易理解 view 的全局。舉例來說，你可能看過長這樣的 view：

```html+erb
<%= render "shared/ad_banner" %>

<h1>Products</h1>

<p>Here are a few of our fine products:</p>
<% @products.each do |product| %>
  <%= render partial: "product", locals: {product: product} %>
<% end %>

<%= render "shared/footer" %>
```

這裡的 `_ad_banner.html.erb` 及 `_footer.html.erb` 局部頁面可以包含你的應用程式裡其它頁面可以共用的內容。這樣一來在寫各個頁面時，就不需要去關注這些瑣碎的細節。

#### `as` 及 `object` 選項

`ActionView::Partials::PartialRenderer` 預設會有個物件，存在與模版名稱相同的變數中。例如：

```erb
<%= render partial: "product" %>
```

在局部頁面中，我們會把 `@product` 存在區域變數 `product` 中。就如同我們寫了：

```erb
<%= render partial: "product", locals: {product: @product} %>
```

用 `as` 選項，我們可以改用其它的區域變數名稱。例如當我們想用 `item` 取代 `product` 時，我們會這樣寫：

```erb
<%= render partial: "product", as: "item" %>
```

而 `object` 選項讓我們可以直接指定要算繪到局部頁面中的物件。這會用於模版頁面的物件存在其它地方時。(例如： 要算繪的物件是另一個實例物件，或是存在某個區域變數裡。)

例如想用這種方法寫時：

```erb
<%= render partial: "product", locals: {product: @item} %>
```

我們會改成這樣：

```erb
<%= render partial: "product", object: @item %>
```

`object` 及 `as` 選項可以同時用：

```erb
<%= render partial: "product", object: @item, as: "item" %>
```

#### Rendering Collections

It is very common that a template needs to iterate over a collection and render a sub-template for each of the elements. This pattern has been implemented as a single method that accepts an array and renders a partial for each one of the elements in the array.

So this example for rendering all the products:

```erb
<% @products.each do |product| %>
  <%= render partial: "product", locals: { product: product } %>
<% end %>
```

can be rewritten in a single line:

```erb
<%= render partial: "product", collection: @products %>
```

When a partial is called like this (eg. with a collection), the individual instances of the partial have access to the member of the collection being rendered via a variable named after the partial. In this case, the partial is `_product`, and within it you can refer to `product` to get the instance that is being rendered.

You can use a shorthand syntax for rendering collections. Assuming `@products` is a collection of `Product` instances, you can simply write the following to produce the same result:

```erb
<%= render @products %>
```

Rails determines the name of the partial to use by looking at the model name in the collection, `Product` in this case. In fact, you can even create a heterogeneous collection and render it this way, and Rails will choose the proper partial for each member of the collection.

#### Spacer Templates

You can also specify a second partial to be rendered between instances of the main partial by using the `:spacer_template` option:

```erb
<%= render partial: @products, spacer_template: "product_ruler" %>
```

Rails will render the `_product_ruler` partial (with no data passed to it) between each pair of `_product` partials.

### Layouts

Layouts can be used to render a common view template around the results of Rails controller actions. Typically, every Rails application has a couple of overall layouts that most pages are rendered within. For example, a site might have a layout for a logged in user, and a layout for the marketing or sales side of the site. The logged in user layout might include top-level navigation that should be present across many controller actions. The sales layout for a SaaS app might include top-level navigation for things like "Pricing" and "Contact Us." You would expect each layout to have a different look and feel. You can read more details about Layouts in the [Layouts and Rendering in Rails](layouts_and_rendering.html) guide.

Partial Layouts
---------------

Partials can have their own layouts applied to them. These layouts are different than the ones that are specified globally for the entire action, but they work in a similar fashion.

Let's say we're displaying an article on a page, that should be wrapped in a `div` for display purposes. First, we'll create a new `Article`:

```ruby
Article.create(body: 'Partial Layouts are cool!')
```

In the `show` template, we'll render the `_article` partial wrapped in the `box` layout:

**articles/show.html.erb**

```erb
<%= render partial: 'article', layout: 'box', locals: {article: @article} %>
```

The `box` layout simply wraps the `_article` partial in a `div`:

**articles/_box.html.erb**

```html+erb
<div class='box'>
  <%= yield %>
</div>
```

The `_article` partial wraps the article's `body` in a `div` with the `id` of the article using the `div_for` helper:

**articles/_article.html.erb**

```html+erb
<%= div_for(article) do %>
  <p><%= article.body %></p>
<% end %>
```

this would output the following:

```html
<div class='box'>
  <div id='article_1'>
    <p>Partial Layouts are cool!</p>
  </div>
</div>
```

Note that the partial layout has access to the local `article` variable that was passed into the `render` call. However, unlike application-wide layouts, partial layouts still have the underscore prefix.

You can also render a block of code within a partial layout instead of calling `yield`. For example, if we didn't have the `_article` partial, we could do this instead:

**articles/show.html.erb**

```html+erb
<% render(layout: 'box', locals: {article: @article}) do %>
  <%= div_for(article) do %>
    <p><%= article.body %></p>
  <% end %>
<% end %>
```

Supposing we use the same `_box` partial from above, this would produce the same output as the previous example.

View Paths
----------

TODO...

Overview of helpers provided by Action View
-------------------------------------------

WIP: Not all the helpers are listed here. For a full list see the [API documentation](http://api.rubyonrails.org/classes/ActionView/Helpers.html)

The following is only a brief overview summary of the helpers available in Action View. It's recommended that you review the [API Documentation](http://api.rubyonrails.org/classes/ActionView/Helpers.html), which covers all of the helpers in more detail, but this should serve as a good starting point.

### RecordTagHelper

This module provides methods for generating container tags, such as `div`, for your record. This is the recommended way of creating a container for render your Active Record object, as it adds an appropriate class and id attributes to that container. You can then refer to those containers easily by following the convention, instead of having to think about which class or id attribute you should use.

#### content_tag_for

Renders a container tag that relates to your Active Record Object.

For example, given `@article` is the object of `Article` class, you can do:

```html+erb
<%= content_tag_for(:tr, @article) do %>
  <td><%= @article.title %></td>
<% end %>
```

This will generate this HTML output:

```html
<tr id="article_1234" class="article">
  <td>Hello World!</td>
</tr>
```

You can also supply HTML attributes as an additional option hash. For example:

```html+erb
<%= content_tag_for(:tr, @article, class: "frontpage") do %>
  <td><%= @article.title %></td>
<% end %>
```

Will generate this HTML output:

```html
<tr id="article_1234" class="article frontpage">
  <td>Hello World!</td>
</tr>
```

You can pass a collection of Active Record objects. This method will loop through your objects and create a container for each of them. For example, given `@articles` is an array of two `Article` objects:

```html+erb
<%= content_tag_for(:tr, @articles) do |article| %>
  <td><%= article.title %></td>
<% end %>
```

Will generate this HTML output:

```html
<tr id="article_1234" class="article">
  <td>Hello World!</td>
</tr>
<tr id="article_1235" class="article">
  <td>Ruby on Rails Rocks!</td>
</tr>
```

#### div_for

This is actually a convenient method which calls `content_tag_for` internally with `:div` as the tag name. You can pass either an Active Record object or a collection of objects. For example:

```html+erb
<%= div_for(@article, class: "frontpage") do %>
  <td><%= @article.title %></td>
<% end %>
```

Will generate this HTML output:

```html
<div id="article_1234" class="article frontpage">
  <td>Hello World!</td>
</div>
```

### AssetTagHelper

This module provides methods for generating HTML that links views to assets such as images, JavaScript files, stylesheets, and feeds.

By default, Rails links to these assets on the current host in the public folder, but you can direct Rails to link to assets from a dedicated assets server by setting `config.action_controller.asset_host` in the application configuration, typically in `config/environments/production.rb`. For example, let's say your asset host is `assets.example.com`:

```ruby
config.action_controller.asset_host = "assets.example.com"
image_tag("rails.png") # => <img src="http://assets.example.com/images/rails.png" alt="Rails" />
```

#### register_javascript_expansion

Register one or more JavaScript files to be included when symbol is passed to javascript_include_tag. This method is typically intended to be called from plugin initialization to register JavaScript files that the plugin installed in `vendor/assets/javascripts`.

```ruby
ActionView::Helpers::AssetTagHelper.register_javascript_expansion monkey: ["head", "body", "tail"]

javascript_include_tag :monkey # =>
  <script src="/assets/head.js"></script>
  <script src="/assets/body.js"></script>
  <script src="/assets/tail.js"></script>
```

#### register_stylesheet_expansion

Register one or more stylesheet files to be included when symbol is passed to `stylesheet_link_tag`. This method is typically intended to be called from plugin initialization to register stylesheet files that the plugin installed in `vendor/assets/stylesheets`.

```ruby
ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion monkey: ["head", "body", "tail"]

stylesheet_link_tag :monkey # =>
  <link href="/assets/head.css" media="screen" rel="stylesheet" />
  <link href="/assets/body.css" media="screen" rel="stylesheet" />
  <link href="/assets/tail.css" media="screen" rel="stylesheet" />
```

#### auto_discovery_link_tag

Returns a link tag that browsers and feed readers can use to auto-detect an RSS or Atom feed.

```ruby
auto_discovery_link_tag(:rss, "http://www.example.com/feed.rss", {title: "RSS Feed"}) # =>
  <link rel="alternate" type="application/rss+xml" title="RSS Feed" href="http://www.example.com/feed" />
```

#### image_path

Computes the path to an image asset in the `app/assets/images` directory. Full paths from the document root will be passed through. Used internally by `image_tag` to build the image path.

```ruby
image_path("edit.png") # => /assets/edit.png
```

Fingerprint will be added to the filename if config.assets.digest is set to true.

```ruby
image_path("edit.png") # => /assets/edit-2d1a2db63fc738690021fedb5a65b68e.png
```

#### image_url

Computes the url to an image asset in the `app/assets/images` directory. This will call `image_path` internally and merge with your current host or your asset host.

```ruby
image_url("edit.png") # => http://www.example.com/assets/edit.png
```

#### image_tag

Returns an html image tag for the source. The source can be a full path or a file that exists in your `app/assets/images` directory.

```ruby
image_tag("icon.png") # => <img src="/assets/icon.png" alt="Icon" />
```

#### javascript_include_tag

Returns an html script tag for each of the sources provided. You can pass in the filename (`.js` extension is optional) of JavaScript files that exist in your `app/assets/javascripts` directory for inclusion into the current page or you can pass the full path relative to your document root.

```ruby
javascript_include_tag "common" # => <script src="/assets/common.js"></script>
```

If the application does not use the asset pipeline, to include the jQuery JavaScript library in your application, pass `:defaults` as the source. When using `:defaults`, if an `application.js` file exists in your `app/assets/javascripts` directory, it will be included as well.

```ruby
javascript_include_tag :defaults
```

You can also include all JavaScript files in the `app/assets/javascripts` directory using `:all` as the source.

```ruby
javascript_include_tag :all
```

You can also cache multiple JavaScript files into one file, which requires less HTTP connections to download and can better be compressed by gzip (leading to faster transfers). Caching will only happen if `ActionController::Base.perform_caching` is set to true (which is the case by default for the Rails production environment, but not for the development environment).

```ruby
javascript_include_tag :all, cache: true # =>
  <script src="/javascripts/all.js"></script>
```

#### javascript_path

Computes the path to a JavaScript asset in the `app/assets/javascripts` directory. If the source filename has no extension, `.js` will be appended. Full paths from the document root will be passed through. Used internally by `javascript_include_tag` to build the script path.

```ruby
javascript_path "common" # => /assets/common.js
```

#### javascript_url

Computes the url to a JavaScript asset in the `app/assets/javascripts` directory. This will call `javascript_path` internally and merge with your current host or your asset host.

```ruby
javascript_url "common" # => http://www.example.com/assets/common.js
```

#### stylesheet_link_tag

Returns a stylesheet link tag for the sources specified as arguments. If you don't specify an extension, `.css` will be appended automatically.

```ruby
stylesheet_link_tag "application" # => <link href="/assets/application.css" media="screen" rel="stylesheet" />
```

You can also include all styles in the stylesheet directory using :all as the source:

```ruby
stylesheet_link_tag :all
```

You can also cache multiple stylesheets into one file, which requires less HTTP connections and can better be compressed by gzip (leading to faster transfers). Caching will only happen if ActionController::Base.perform_caching is set to true (which is the case by default for the Rails production environment, but not for the development environment).

```ruby
stylesheet_link_tag :all, cache: true
# => <link href="/assets/all.css" media="screen" rel="stylesheet" />
```

#### stylesheet_path

Computes the path to a stylesheet asset in the `app/assets/stylesheets` directory. If the source filename has no extension, .css will be appended. Full paths from the document root will be passed through. Used internally by stylesheet_link_tag to build the stylesheet path.

```ruby
stylesheet_path "application" # => /assets/application.css
```

#### stylesheet_url

Computes the url to a stylesheet asset in the `app/assets/stylesheets` directory. This will call `stylesheet_path` internally and merge with your current host or your asset host.

```ruby
stylesheet_url "application" # => http://www.example.com/assets/application.css
```

### AtomFeedHelper

#### atom_feed

This helper makes building an Atom feed easy. Here's a full usage example:

**config/routes.rb**

```ruby
resources :articles
```

**app/controllers/articles_controller.rb**

```ruby
def index
  @articles = Article.all

  respond_to do |format|
    format.html
    format.atom
  end
end
```

**app/views/articles/index.atom.builder**

```ruby
atom_feed do |feed|
  feed.title("Articles Index")
  feed.updated((@articles.first.created_at))

  @articles.each do |article|
    feed.entry(article) do |entry|
      entry.title(article.title)
      entry.content(article.body, type: 'html')

      entry.author do |author|
        author.name(article.author_name)
      end
    end
  end
end
```

### BenchmarkHelper

#### benchmark

Allows you to measure the execution time of a block in a template and records the result to the log. Wrap this block around expensive operations or possible bottlenecks to get a time reading for the operation.

```html+erb
<% benchmark "Process data files" do %>
  <%= expensive_files_operation %>
<% end %>
```

This would add something like "Process data files (0.34523)" to the log, which you can then use to compare timings when optimizing your code.

### CacheHelper

#### cache

A method for caching fragments of a view rather than an entire action or page. This technique is useful caching pieces like menus, lists of news topics, static HTML fragments, and so on. This method takes a block that contains the content you wish to cache. See `ActionController::Caching::Fragments` for more information.

```erb
<% cache do %>
  <%= render "shared/footer" %>
<% end %>
```

### CaptureHelper

#### capture

The `capture` method allows you to extract part of a template into a variable. You can then use this variable anywhere in your templates or layout.

```html+erb
<% @greeting = capture do %>
  <p>Welcome! The date and time is <%= Time.now %></p>
<% end %>
```

The captured variable can then be used anywhere else.

```html+erb
<html>
  <head>
    <title>Welcome!</title>
  </head>
  <body>
    <%= @greeting %>
  </body>
</html>
```

#### content_for

Calling `content_for` stores a block of markup in an identifier for later use. You can make subsequent calls to the stored content in other templates or the layout by passing the identifier as an argument to `yield`.

For example, let's say we have a standard application layout, but also a special page that requires certain JavaScript that the rest of the site doesn't need. We can use `content_for` to include this JavaScript on our special page without fattening up the rest of the site.

**app/views/layouts/application.html.erb**

```html+erb
<html>
  <head>
    <title>Welcome!</title>
    <%= yield :special_script %>
  </head>
  <body>
    <p>Welcome! The date and time is <%= Time.now %></p>
  </body>
</html>
```

**app/views/articles/special.html.erb**

```html+erb
<p>This is a special page.</p>

<% content_for :special_script do %>
  <script>alert('Hello!')</script>
<% end %>
```

### DateHelper

#### date_select

Returns a set of select tags (one for year, month, and day) pre-selected for accessing a specified date-based attribute.

```ruby
date_select("article", "published_on")
```

#### datetime_select

Returns a set of select tags (one for year, month, day, hour, and minute) pre-selected for accessing a specified datetime-based attribute.

```ruby
datetime_select("article", "published_on")
```

#### distance_of_time_in_words

Reports the approximate distance in time between two Time or Date objects or integers as seconds. Set `include_seconds` to true if you want more detailed approximations.

```ruby
distance_of_time_in_words(Time.now, Time.now + 15.seconds)        # => less than a minute
distance_of_time_in_words(Time.now, Time.now + 15.seconds, include_seconds: true)  # => less than 20 seconds
```

#### select_date

Returns a set of html select-tags (one for year, month, and day) pre-selected with the `date` provided.

```ruby
# Generates a date select that defaults to the date provided (six days after today)
select_date(Time.today + 6.days)

# Generates a date select that defaults to today (no specified date)
select_date()
```

#### select_datetime

Returns a set of html select-tags (one for year, month, day, hour, and minute) pre-selected with the `datetime` provided.

```ruby
# Generates a datetime select that defaults to the datetime provided (four days after today)
select_datetime(Time.now + 4.days)

# Generates a datetime select that defaults to today (no specified datetime)
select_datetime()
```

#### select_day

Returns a select tag with options for each of the days 1 through 31 with the current day selected.

```ruby
# Generates a select field for days that defaults to the day for the date provided
select_day(Time.today + 2.days)

# Generates a select field for days that defaults to the number given
select_day(5)
```

#### select_hour

Returns a select tag with options for each of the hours 0 through 23 with the current hour selected.

```ruby
# Generates a select field for hours that defaults to the hours for the time provided
select_hour(Time.now + 6.hours)
```

#### select_minute

Returns a select tag with options for each of the minutes 0 through 59 with the current minute selected.

```ruby
# Generates a select field for minutes that defaults to the minutes for the time provided.
select_minute(Time.now + 6.hours)
```

#### select_month

Returns a select tag with options for each of the months January through December with the current month selected.

```ruby
# Generates a select field for months that defaults to the current month
select_month(Date.today)
```

#### select_second

Returns a select tag with options for each of the seconds 0 through 59 with the current second selected.

```ruby
# Generates a select field for seconds that defaults to the seconds for the time provided
select_second(Time.now + 16.minutes)
```

#### select_time

Returns a set of html select-tags (one for hour and minute).

```ruby
# Generates a time select that defaults to the time provided
select_time(Time.now)
```

#### select_year

Returns a select tag with options for each of the five years on each side of the current, which is selected. The five year radius can be changed using the `:start_year` and `:end_year` keys in the `options`.

```ruby
# Generates a select field for five years on either side of Date.today that defaults to the current year
select_year(Date.today)

# Generates a select field from 1900 to 2009 that defaults to the current year
select_year(Date.today, start_year: 1900, end_year: 2009)
```

#### time_ago_in_words

Like `distance_of_time_in_words`, but where `to_time` is fixed to `Time.now`.

```ruby
time_ago_in_words(3.minutes.from_now)  # => 3 minutes
```

#### time_select

Returns a set of select tags (one for hour, minute and optionally second) pre-selected for accessing a specified time-based attribute. The selects are prepared for multi-parameter assignment to an Active Record object.

```ruby
# Creates a time select tag that, when POSTed, will be stored in the order variable in the submitted attribute
time_select("order", "submitted")
```

### DebugHelper

Returns a `pre` tag that has object dumped by YAML. This creates a very readable way to inspect an object.

```ruby
my_hash = {'first' => 1, 'second' => 'two', 'third' => [1,2,3]}
debug(my_hash)
```

```html
<pre class='debug_dump'>---
first: 1
second: two
third:
- 1
- 2
- 3
</pre>
```

### FormHelper

Form helpers are designed to make working with models much easier compared to using just standard HTML elements by providing a set of methods for creating forms based on your models. This helper generates the HTML for forms, providing a method for each sort of input (e.g., text, password, select, and so on). When the form is submitted (i.e., when the user hits the submit button or form.submit is called via JavaScript), the form inputs will be bundled into the params object and passed back to the controller.

There are two types of form helpers: those that specifically work with model attributes and those that don't. This helper deals with those that work with model attributes; to see an example of form helpers that don't work with model attributes, check the ActionView::Helpers::FormTagHelper documentation.

The core method of this helper, form_for, gives you the ability to create a form for a model instance; for example, let's say that you have a model Person and want to create a new instance of it:

```html+erb
# Note: a @person variable will have been created in the controller (e.g. @person = Person.new)
<%= form_for @person, url: {action: "create"} do |f| %>
  <%= f.text_field :first_name %>
  <%= f.text_field :last_name %>
  <%= submit_tag 'Create' %>
<% end %>
```

The HTML generated for this would be:

```html
<form action="/people/create" method="post">
  <input id="person_first_name" name="person[first_name]" type="text" />
  <input id="person_last_name" name="person[last_name]" type="text" />
  <input name="commit" type="submit" value="Create" />
</form>
```

The params object created when this form is submitted would look like:

```ruby
{"action" => "create", "controller" => "people", "person" => {"first_name" => "William", "last_name" => "Smith"}}
```

The params hash has a nested person value, which can therefore be accessed with params[:person] in the controller.

#### check_box

Returns a checkbox tag tailored for accessing a specified attribute.

```ruby
# Let's say that @article.validated? is 1:
check_box("article", "validated")
# => <input type="checkbox" id="article_validated" name="article[validated]" value="1" />
#    <input name="article[validated]" type="hidden" value="0" />
```

#### fields_for

Creates a scope around a specific model object like form_for, but doesn't create the form tags themselves. This makes fields_for suitable for specifying additional model objects in the same form:

```html+erb
<%= form_for @person, url: {action: "update"} do |person_form| %>
  First name: <%= person_form.text_field :first_name %>
  Last name : <%= person_form.text_field :last_name %>

  <%= fields_for @person.permission do |permission_fields| %>
    Admin?  : <%= permission_fields.check_box :admin %>
  <% end %>
<% end %>
```

#### file_field

Returns a file upload input tag tailored for accessing a specified attribute.

```ruby
file_field(:user, :avatar)
# => <input type="file" id="user_avatar" name="user[avatar]" />
```

#### form_for

Creates a form and a scope around a specific model object that is used as a base for questioning about values for the fields.

```html+erb
<%= form_for @article do |f| %>
  <%= f.label :title, 'Title' %>:
  <%= f.text_field :title %><br>
  <%= f.label :body, 'Body' %>:
  <%= f.text_area :body %><br>
<% end %>
```

#### hidden_field

Returns a hidden input tag tailored for accessing a specified attribute.

```ruby
hidden_field(:user, :token)
# => <input type="hidden" id="user_token" name="user[token]" value="#{@user.token}" />
```

#### label

Returns a label tag tailored for labelling an input field for a specified attribute.

```ruby
label(:article, :title)
# => <label for="article_title">Title</label>
```

#### password_field

Returns an input tag of the "password" type tailored for accessing a specified attribute.

```ruby
password_field(:login, :pass)
# => <input type="text" id="login_pass" name="login[pass]" value="#{@login.pass}" />
```

#### radio_button

Returns a radio button tag for accessing a specified attribute.

```ruby
# Let's say that @article.category returns "rails":
radio_button("article", "category", "rails")
radio_button("article", "category", "java")
# => <input type="radio" id="article_category_rails" name="article[category]" value="rails" checked="checked" />
#    <input type="radio" id="article_category_java" name="article[category]" value="java" />
```

#### text_area

Returns a textarea opening and closing tag set tailored for accessing a specified attribute.

```ruby
text_area(:comment, :text, size: "20x30")
# => <textarea cols="20" rows="30" id="comment_text" name="comment[text]">
#      #{@comment.text}
#    </textarea>
```

#### text_field

Returns an input tag of the "text" type tailored for accessing a specified attribute.

```ruby
text_field(:article, :title)
# => <input type="text" id="article_title" name="article[title]" value="#{@article.title}" />
```

#### email_field

Returns an input tag of the "email" type tailored for accessing a specified attribute.

```ruby
email_field(:user, :email)
# => <input type="email" id="user_email" name="user[email]" value="#{@user.email}" />
```

#### url_field

Returns an input tag of the "url" type tailored for accessing a specified attribute.

```ruby
url_field(:user, :url)
# => <input type="url" id="user_url" name="user[url]" value="#{@user.url}" />
```

### FormOptionsHelper

Provides a number of methods for turning different kinds of containers into a set of option tags.

#### collection_select

Returns `select` and `option` tags for the collection of existing return values of `method` for `object`'s class.

Example object structure for use with this method:

```ruby
class Article < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :articles
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

Sample usage (selecting the associated Author for an instance of Article, `@article`):

```ruby
collection_select(:article, :author_id, Author.all, :id, :name_with_initial, {prompt: true})
```

If `@article.author_id` is 1, this would return:

```html
<select name="article[author_id]">
  <option value="">Please select</option>
  <option value="1" selected="selected">D. Heinemeier Hansson</option>
  <option value="2">D. Thomas</option>
  <option value="3">M. Clark</option>
</select>
```

#### collection_radio_buttons

Returns `radio_button` tags for the collection of existing return values of `method` for `object`'s class.

Example object structure for use with this method:

```ruby
class Article < ActiveRecord::Base
  belongs_to :author
end

class Author < ActiveRecord::Base
  has_many :articles
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

Sample usage (selecting the associated Author for an instance of Article, `@article`):

```ruby
collection_radio_buttons(:article, :author_id, Author.all, :id, :name_with_initial)
```

If `@article.author_id` is 1, this would return:

```html
<input id="article_author_id_1" name="article[author_id]" type="radio" value="1" checked="checked" />
<label for="article_author_id_1">D. Heinemeier Hansson</label>
<input id="article_author_id_2" name="article[author_id]" type="radio" value="2" />
<label for="article_author_id_2">D. Thomas</label>
<input id="article_author_id_3" name="article[author_id]" type="radio" value="3" />
<label for="article_author_id_3">M. Clark</label>
```

#### collection_check_boxes

Returns `check_box` tags for the collection of existing return values of `method` for `object`'s class.

Example object structure for use with this method:

```ruby
class Article < ActiveRecord::Base
  has_and_belongs_to_many :authors
end

class Author < ActiveRecord::Base
  has_and_belongs_to_many :articles
  def name_with_initial
    "#{first_name.first}. #{last_name}"
  end
end
```

Sample usage (selecting the associated Authors for an instance of Article, `@article`):

```ruby
collection_check_boxes(:article, :author_ids, Author.all, :id, :name_with_initial)
```

If `@article.author_ids` is [1], this would return:

```html
<input id="article_author_ids_1" name="article[author_ids][]" type="checkbox" value="1" checked="checked" />
<label for="article_author_ids_1">D. Heinemeier Hansson</label>
<input id="article_author_ids_2" name="article[author_ids][]" type="checkbox" value="2" />
<label for="article_author_ids_2">D. Thomas</label>
<input id="article_author_ids_3" name="article[author_ids][]" type="checkbox" value="3" />
<label for="article_author_ids_3">M. Clark</label>
<input name="article[author_ids][]" type="hidden" value="" />
```

#### country_options_for_select

Returns a string of option tags for pretty much any country in the world.

#### country_select

Returns select and option tags for the given object and method, using country_options_for_select to generate the list of option tags.

#### option_groups_from_collection_for_select

Returns a string of `option` tags, like `options_from_collection_for_select`, but groups them by `optgroup` tags based on the object relationships of the arguments.

Example object structure for use with this method:

```ruby
class Continent < ActiveRecord::Base
  has_many :countries
  # attribs: id, name
end

class Country < ActiveRecord::Base
  belongs_to :continent
  # attribs: id, name, continent_id
end
```

Sample usage:

```ruby
option_groups_from_collection_for_select(@continents, :countries, :name, :id, :name, 3)
```

Possible output:

```html
<optgroup label="Africa">
  <option value="1">Egypt</option>
  <option value="4">Rwanda</option>
  ...
</optgroup>
<optgroup label="Asia">
  <option value="3" selected="selected">China</option>
  <option value="12">India</option>
  <option value="5">Japan</option>
  ...
</optgroup>
```

Note: Only the `optgroup` and `option` tags are returned, so you still have to wrap the output in an appropriate `select` tag.

#### options_for_select

Accepts a container (hash, array, enumerable, your type) and returns a string of option tags.

```ruby
options_for_select([ "VISA", "MasterCard" ])
# => <option>VISA</option> <option>MasterCard</option>
```

Note: Only the `option` tags are returned, you have to wrap this call in a regular HTML `select` tag.

#### options_from_collection_for_select

Returns a string of option tags that have been compiled by iterating over the `collection` and assigning the result of a call to the `value_method` as the option value and the `text_method` as the option text.

```ruby
# options_from_collection_for_select(collection, value_method, text_method, selected = nil)
```

For example, imagine a loop iterating over each person in @project.people to generate an input tag:

```ruby
options_from_collection_for_select(@project.people, "id", "name")
# => <option value="#{person.id}">#{person.name}</option>
```

Note: Only the `option` tags are returned, you have to wrap this call in a regular HTML `select` tag.

#### select

Create a select tag and a series of contained option tags for the provided object and method.

Example:

```ruby
select("article", "person_id", Person.all.collect {|p| [ p.name, p.id ] }, {include_blank: true})
```

If `@article.person_id` is 1, this would become:

```html
<select name="article[person_id]">
  <option value=""></option>
  <option value="1" selected="selected">David</option>
  <option value="2">Sam</option>
  <option value="3">Tobias</option>
</select>
```

#### time_zone_options_for_select

Returns a string of option tags for pretty much any time zone in the world.

#### time_zone_select

Returns select and option tags for the given object and method, using `time_zone_options_for_select` to generate the list of option tags.

```ruby
time_zone_select( "user", "time_zone")
```

#### date_field

Returns an input tag of the "date" type tailored for accessing a specified attribute.

```ruby
date_field("user", "dob")
```

### FormTagHelper

Provides a number of methods for creating form tags that don't rely on an Active Record object assigned to the template like FormHelper does. Instead, you provide the names and values manually.

#### check_box_tag

Creates a check box form input tag.

```ruby
check_box_tag 'accept'
# => <input id="accept" name="accept" type="checkbox" value="1" />
```

#### field_set_tag

Creates a field set for grouping HTML form elements.

```html+erb
<%= field_set_tag do %>
  <p><%= text_field_tag 'name' %></p>
<% end %>
# => <fieldset><p><input id="name" name="name" type="text" /></p></fieldset>
```

#### file_field_tag

Creates a file upload field.

```html+erb
<%= form_tag({action:"post"}, multipart: true) do %>
  <label for="file">File to Upload</label> <%= file_field_tag "file" %>
  <%= submit_tag %>
<% end %>
```

Example output:

```ruby
file_field_tag 'attachment'
# => <input id="attachment" name="attachment" type="file" />
```

#### form_tag

Starts a form tag that points the action to an url configured with `url_for_options` just like `ActionController::Base#url_for`.

```html+erb
<%= form_tag '/articles' do %>
  <div><%= submit_tag 'Save' %></div>
<% end %>
# => <form action="/articles" method="post"><div><input type="submit" name="submit" value="Save" /></div></form>
```

#### hidden_field_tag

Creates a hidden form input field used to transmit data that would be lost due to HTTP's statelessness or data that should be hidden from the user.

```ruby
hidden_field_tag 'token', 'VUBJKB23UIVI1UU1VOBVI@'
# => <input id="token" name="token" type="hidden" value="VUBJKB23UIVI1UU1VOBVI@" />
```

#### image_submit_tag

Displays an image which when clicked will submit the form.

```ruby
image_submit_tag("login.png")
# => <input src="/images/login.png" type="image" />
```

#### label_tag

Creates a label field.

```ruby
label_tag 'name'
# => <label for="name">Name</label>
```

#### password_field_tag

Creates a password field, a masked text field that will hide the users input behind a mask character.

```ruby
password_field_tag 'pass'
# => <input id="pass" name="pass" type="password" />
```

#### radio_button_tag

Creates a radio button; use groups of radio buttons named the same to allow users to select from a group of options.

```ruby
radio_button_tag 'gender', 'male'
# => <input id="gender_male" name="gender" type="radio" value="male" />
```

#### select_tag

Creates a dropdown selection box.

```ruby
select_tag "people", "<option>David</option>"
# => <select id="people" name="people"><option>David</option></select>
```

#### submit_tag

Creates a submit button with the text provided as the caption.

```ruby
submit_tag "Publish this article"
# => <input name="commit" type="submit" value="Publish this article" />
```

#### text_area_tag

Creates a text input area; use a textarea for longer text inputs such as blog posts or descriptions.

```ruby
text_area_tag 'article'
# => <textarea id="article" name="article"></textarea>
```

#### text_field_tag

Creates a standard text field; use these text fields to input smaller chunks of text like a username or a search query.

```ruby
text_field_tag 'name'
# => <input id="name" name="name" type="text" />
```

#### email_field_tag

Creates a standard input field of email type.

```ruby
email_field_tag 'email'
# => <input id="email" name="email" type="email" />
```

#### url_field_tag

Creates a standard input field of url type.

```ruby
url_field_tag 'url'
# => <input id="url" name="url" type="url" />
```

#### date_field_tag

Creates a standard input field of date type.

```ruby
date_field_tag "dob"
# => <input id="dob" name="dob" type="date" />
```

### JavaScriptHelper

Provides functionality for working with JavaScript in your views.

#### button_to_function

Returns a button that'll trigger a JavaScript function using the onclick handler. Examples:

```ruby
button_to_function "Greeting", "alert('Hello world!')"
button_to_function "Delete", "if (confirm('Really?')) do_delete()"
button_to_function "Details" do |page|
  page[:details].visual_effect :toggle_slide
end
```

#### define_javascript_functions

Includes the Action Pack JavaScript libraries inside a single `script` tag.

#### escape_javascript

Escape carrier returns and single and double quotes for JavaScript segments.

#### javascript_tag

Returns a JavaScript tag wrapping the provided code.

```ruby
javascript_tag "alert('All is good')"
```

```html
<script>
//<![CDATA[
alert('All is good')
//]]>
</script>
```

#### link_to_function

Returns a link that will trigger a JavaScript function using the onclick handler and return false after the fact.

```ruby
link_to_function "Greeting", "alert('Hello world!')"
# => <a onclick="alert('Hello world!'); return false;" href="#">Greeting</a>
```

### NumberHelper

Provides methods for converting numbers into formatted strings. Methods are provided for phone numbers, currency, percentage, precision, positional notation, and file size.

#### number_to_currency

Formats a number into a currency string (e.g., $13.65).

```ruby
number_to_currency(1234567890.50) # => $1,234,567,890.50
```

#### number_to_human_size

Formats the bytes in size into a more understandable representation; useful for reporting file sizes to users.

```ruby
number_to_human_size(1234)          # => 1.2 KB
number_to_human_size(1234567)       # => 1.2 MB
```

#### number_to_percentage

Formats a number as a percentage string.

```ruby
number_to_percentage(100, precision: 0)        # => 100%
```

#### number_to_phone

Formats a number into a US phone number.

```ruby
number_to_phone(1235551234) # => 123-555-1234
```

#### number_with_delimiter

Formats a number with grouped thousands using a delimiter.

```ruby
number_with_delimiter(12345678) # => 12,345,678
```

#### number_with_precision

Formats a number with the specified level of `precision`, which defaults to 3.

```ruby
number_with_precision(111.2345)     # => 111.235
number_with_precision(111.2345, 2)  # => 111.23
```

### SanitizeHelper

The SanitizeHelper module provides a set of methods for scrubbing text of undesired HTML elements.

#### sanitize

This sanitize helper will html encode all tags and strip all attributes that aren't specifically allowed.

```ruby
sanitize @article.body
```

If either the :attributes or :tags options are passed, only the mentioned tags and attributes are allowed and nothing else.

```ruby
sanitize @article.body, tags: %w(table tr td), attributes: %w(id class style)
```

To change defaults for multiple uses, for example adding table tags to the default:

```ruby
class Application < Rails::Application
  config.action_view.sanitized_allowed_tags = 'table', 'tr', 'td'
end
```

#### sanitize_css(style)

Sanitizes a block of CSS code.

#### strip_links(html)
Strips all link tags from text leaving just the link text.

```ruby
strip_links("<a href="http://rubyonrails.org">Ruby on Rails</a>")
# => Ruby on Rails
```

```ruby
strip_links("emails to <a href="mailto:me@email.com">me@email.com</a>.")
# => emails to me@email.com.
```

```ruby
strip_links('Blog: <a href="http://myblog.com/">Visit</a>.')
# => Blog: Visit.
```

#### strip_tags(html)

Strips all HTML tags from the html, including comments.
This uses the html-scanner tokenizer and so its HTML parsing ability is limited by that of html-scanner.

```ruby
strip_tags("Strip <i>these</i> tags!")
# => Strip these tags!
```

```ruby
strip_tags("<b>Bold</b> no more!  <a href='more.html'>See more</a>")
# => Bold no more!  See more
```

NB: The output may still contain unescaped '<', '>', '&' characters and confuse browsers.

### CsrfHelper

Returns meta tags "csrf-param" and "csrf-token" with the name of the cross-site
request forgery protection parameter and token, respectively.

```html
<%= csrf_meta_tags %>
```

NOTE: Regular forms generate hidden fields so they do not use these tags. More
details can be found in the [Rails Security Guide](security.html#cross-site-request-forgery-csrf).

Localized Views
---------------

Action View has the ability render different templates depending on the current locale.

For example, suppose you have a `ArticlesController` with a show action. By default, calling this action will render `app/views/articles/show.html.erb`. But if you set `I18n.locale = :de`, then `app/views/articles/show.de.html.erb` will be rendered instead. If the localized template isn't present, the undecorated version will be used. This means you're not required to provide localized views for all cases, but they will be preferred and used if available.

You can use the same technique to localize the rescue files in your public directory. For example, setting `I18n.locale = :de` and creating `public/500.de.html` and `public/404.de.html` would allow you to have localized rescue pages.

Since Rails doesn't restrict the symbols that you use to set I18n.locale, you can leverage this system to display different content depending on anything you like. For example, suppose you have some "expert" users that should see different pages from "normal" users. You could add the following to `app/controllers/application.rb`:

```ruby
before_action :set_expert_locale

def set_expert_locale
  I18n.locale = :expert if current_user.expert?
end
```

Then you could create special views like `app/views/articles/show.expert.html.erb` that would only be displayed to expert users.

You can read more about the Rails Internationalization (I18n) API [here](i18n.html).
