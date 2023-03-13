# SimpleTrail

Component to store change history of your model.

## Usage

```ruby
class Project < ApplicationRecord
  include ::SimpleTrail::Recordable
end
```

Now you can access the object history through `SimpleTrail.for(object)` like:

```ruby
project = Project.create
SimpleTrail.for(project).size
# => 1
```

The user performing the action will be recorded from the Thread local `:user_id`.
