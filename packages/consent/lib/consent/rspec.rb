# frozen_string_literal: true

require 'consent'

require_relative 'rspec/consent_action'
require_relative 'rspec/consent_view'

module Consent
  # RSpec helpers for consent. Given permissions are loaded,
  # gives you the ability of defining permission specs like
  #
  # Given "users" permissions
  # Consent.define :users, "User management" do
  #   view :department, "Same department only" do |user|
  #     { department_id: user.department_id }
  #   end
  #   action :read, "Can view users"
  #   action :update, "Can edit existing user", views: :department
  # end
  #
  # RSpec.describe "User permissions" do
  #   include Consent::Rspec
  #   let(:user) { double(department_id: 15) }
  #
  #   it do
  #     is_expected.to(
  #       consent_view(:department)
  #         .with_conditions(department_id: 15)
  #         .to(user)
  #     )
  #   end
  #   it { is_expected.to consent_action(:read) }
  #   it { is_expected.to consent_action(:update).with_views(:department) }
  # end
  #
  # Find more examples at:
  # https://github.com/powerhome/consent
  module Rspec
    def consent_view(view_key, conditions = nil)
      ConsentView.new(view_key, conditions)
    end

    def consent_action(action_key)
      ConsentAction.new(action_key)
    end
  end
end
