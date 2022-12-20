# *NOTICE:* This app is in its _experimental_ phase and a stable version has not yet been released

# Rabbet 🐰

![rabbet-definition](https://user-images.githubusercontent.com/16630021/208455743-bf14911b-ddc3-4076-bcdb-3ebceb241ee9.png)

At [Power](https://techatpower.com), we have a suite of applications that provide a wealth of functionality to our users, many of which were broken out from our monolith. We want all of these applications to have the same look and feel and cohesive experience. While we rely on [playbook](https://playbook.powerapp.cloud/) for specific components, we want to put some of these components and other pieces together to give us a framework for the general layout and functionality for a top menu, sidebar, and other components that are likely to be consistently framing every page of the monolith. We also want to provide some injectable containers so that applications can magically add their own functionality into this frame if they would like to do so.

Rabbet is a convenient place to store these shared pieces and configure them based on the needs of the individual application.

## Installation 🥕

1. Add the gem to your gemfile and bundle.

`gem "rabbet"`

1. Require the gem

```ruby
# lib/my_cool_app.rb or application.rb

require "rabbet"
```

1. Add the styles to your application.

```ruby
# application.scss

@import "rabbet";
```

1. Include the view helpers to help with injection

```ruby
# application_helper.rb

include Rabbet::Views::Helpers

```

## Usage 🐇

You can find a list of available pieces in [app/views/rabbet](https://github.com/powerhome/power-tools/blob/main/packages/rabbet/app/views/rabbet/). If, for example, you'd like to add the topbar to your application, you can view the injectible pieces in [that specific file](https://github.com/powerhome/power-tools/blob/main/packages/rabbet/app/views/rabbet/_topbar.html.erb). In topbar, pieces that are injectible include:

* `logo`
* `header`
* `navigation_right`

![annotated-topbar-example-one](https://user-images.githubusercontent.com/16630021/207151184-af939059-4dff-4382-ab53-f37fb57574fd.png)

![annotated-topbar-example-two](https://user-images.githubusercontent.com/16630021/207151180-875c36ef-7e45-4b52-808b-33497c85ca8e.png)


In our example we'll add the topbar, but we only want to inject the logo into our app. We would do so like so:

```ruby
<% content_for :logo do %>
  <%= image_tag("path_to/logo_image/here.png") %>
<% end %>

<%= render partial: "rabbet/topbar" %>
```

By default, the color for the topbar will be the blue that Power's monolith uses. This is configurable, however, by passing in your chosen color as a local variable:

```ruby
<%= render partial: "rabbet/topbar",
    locals: { bg_color: "#282634"} %>
```
