$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cancan'
require 'cancan/matchers'
require 'active_support/inflector'
require 'nitro/consent'

SomeModel = Struct.new(:name)

Nitro::Consent.define SomeModel, 'My Label' do
  view :self, 'Default view' do |user|
    { owner_id: user.id }
  end

  view :view1, 'View 1'
  view :lol, 'Lol Only' do |_|
    { name: 'lol' }
  end

  action :action1, 'Action One', views: [:view1, :lol]
  action :destroy, 'Destroy', views: [:lol, :self], default_view: :self
end

Nitro::Consent.define :features, 'My Label' do
  action :beta, 'Beta feature'
end
