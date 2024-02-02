# 🛡️ DepShield 🛡️

Introducing DepShield, your go-to Ruby gem for proactive deprecation management in your codebase, making upgrading dependencies easier and faster.

With DepShield, developers can stay ahead of the curve by receiving real-time alerts about deprecated code, ensuring a smoother transition to future updates. Tailor your development and demo environments to raise alarms, preventing the introduction of new deprecations. In addition, DepShield offers the flexibility to configure self-reporting mechanisms, allowing seamless issue notifications, configurable by environment Say goodbye to unexpected deprecation surprises and embrace a more streamlined and informed coding experience with DepShield!

## Setup

After installing DepShield, load any todo lists in your application with:

`DepShield.todos.load("path-to-deprecation_todos.yml")`

## Usage

`DepShield#raise_or_capture!` is used to mark methods as deprecated. When called, it will intelligently warn or raise exceptions to alert developers to the deprecated activity. The method expects two arguments, a `name` (ie, the name of the deprecation you're introducing), and a `message` (usually information about what is deprecated and how to fix it). Marking something as deprecated is pretty simple:

```ruby
# components/books/lib/books.rb

def self.category
  NitroErrors.deprecate!(name: "books_default_category", message: "please use '.default_category' instead")
  "Science Fiction"
end
```

This is used in conjuction with NitroConfig to define how different environment should react:

Option A: the result of this is a logged warning every time the method is called.
Option B: this will raise and notify our error catcher (Sentry).

If a developer needs to bypass this/defer fixing the deprecation to a future date, the call can be "grandfathered" by adding this information to the allowlist in a `.deprecation_todo.yml` file in the application/component that hosts the deprecated reference. For example, if you have a method in the `authors` component that references `Books.category`:

```ruby
# components/authors/lib/book_information.rb

book_category = Books.category
```

You could disable this with:

```yml
# components/authors/.deprecation_todo.yml

books_default_category:
  - components/authors/lib/book_information.rb
```

More details and another example can be found [here](https://github.com/powerhome/power-tools/blob/main/packages/dep_shield/spec/internal/config/.deprecation_todo.yml)
