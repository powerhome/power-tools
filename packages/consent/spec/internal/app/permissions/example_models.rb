# frozen_string_literal: true

Consent.define ExampleModel, "My Label" do
  view :future, "Future only",
       ->(_, model) { model.created_at > Date.today },
       ->(_) { ["created_at > ?", Date.today] }

  view :self, "Default view" do |user|
    { owner_id: user.id }
  end

  view :scoped_self, "Default view",
       ->(_user, _obj) { true },
       ->(user) { ExampleModel.where(owner_id: user.id) }

  view :view1, "View 1"
  view :lol, "Lol Only" do |_|
    { name: "lol" }
  end

  action :action1, "Action One", views: %i[view1 lol]
  action :destroy, "Destroy", views: %i[lol self], default_view: :future
end

Consent.define ExampleModel, "Another for the model" do
  view :lol, "ROFL Only" do |_|
    { name: "ROFL" }
  end

  action :create, "Create", views: %i[lol self]
end
