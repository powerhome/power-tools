# Ruby Slippers 👠👠

_There's no place like the general layout and the top menu for which the home button lives._

At [Power](https://powerhrg.com/#!/career), we have a suite of applications that provide a wealth of functionality to our users, many of which were broken out from our monolith. We want all of these applications to have the same look and feel and cohesive experience. While we rely on [playbook](https://playbook.powerapp.cloud/) for bootstrap-like functionality, we want to put some of these pieces and other things together to give us a general layout and functionality for a top menu bar and other items that are likely to be consistently shown across every page. We also want to provide some injectable containers so that applications can magically add their own functionality into the menu if they would like to do so.

## Installation 🌪️

1. Add the gem to your gemfile and bundle.

`gem "ruby_slippers"`

1. Require the gem

```ruby
# lib/my_cool_app.rb or application.rb

require "ruby_slippers"
```

1. Add the styles to your application.

```ruby
# application.scss

@import "ruby_slippers";
```

## Usage 🌈

You can find a list of available pieces in [app/views/ruby_slippers](https://github.com/powerhome/power-tools/blob/main/packages/ruby_slippers/app/views/ruby_slippers/). If, for example, you'd like to add the topbar to your application, you can view the injectible pieces in [that specific file](https://github.com/powerhome/power-tools/blob/main/packages/ruby_slippers/app/views/ruby_slippers/_topbar.html.erb). In topbar, pieces that are injectible include:

* `env_information`
* `logo`
* `header` (injectible piece at the center of the topbar)
* and dropdowns a through c, which are three injectible dropdowns in a row, left to right

In our example we'll add the topbar, but we only want to inject the logo into our app. We would do so like so:

```ruby
<% content_for :logo do %>
  <%= image_tag("path_to/logo_image/here.png") %>
<% end %>

<%= render partial: "ruby_slippers/topbar" %>
```
