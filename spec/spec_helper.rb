$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cancan'
require 'cancan/matchers'
require 'active_support/inflector'
require 'consent'
require 'date'

SomeModel = Struct.new(:name, :created_at)

Consent.default_views[:no_access] = Consent::View.new('', 'No Access')

Consent.define SomeModel, 'My Label' do
  view :future, 'Future only',
    -> (_, model) { model.created_at > Date.new },
    -> (_) { ['created_at > ?', Date.new] }

  view :self, 'Default view' do |user|
    { owner_id: user.id }
  end

  view :view1, 'View 1'
  view :lol, 'Lol Only' do |_|
    { name: 'lol' }
  end

  action :action1, 'Action One', views: [:view1, :lol]
  action :destroy, 'Destroy', views: [:lol, :self], default_view: :future
end

Consent.define :beta, 'LOL Department (Beta)' do
  action :lol_til_death, 'LOL Until you die'
end

Consent.define :beta, 'Frustration Department (Beta)' do
  action :request_frustration, 'Request Frustration'
end
