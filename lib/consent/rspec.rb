# frozen_string_literal: true

require 'consent'

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
  #     is_expected.to consent_view(:department, department_id: 15).to(user)
  #   end
  #   it { is_expected.to consent_action(:read) }
  #   it { is_expected.to consent_action(:update).with_views(:department) }
  # end
  #
  # Find more examples at:
  # https://github.com/powerhome/consent
  module Rspec
    extend RSpec::Matchers::DSL

    matcher :consent_action do |action_key|
      chain :with_views do |*views|
        @views = views
      end

      match do |subject_key|
        action = Consent.find_action(subject_key, action_key)
        if action && @views
          values_match?(action.views.keys.sort, @views.sort)
        else
          !action.nil?
        end
      end

      failure_message do |subject_key|
        action = Consent.find_action(subject_key, action_key)
        message = format(
          'expected %<skey>s (%<sclass>s) to provide action %<action>s',
          skey: subject_key.to_s, sclass: subject.class, action: action_key
        )

        if action && @views
          format(
            '%<message>s with views %<views>s, but actual views are %<keys>p',
            message: message, views: @views, keys: action.views.keys
          )
        else
          message
        end
      end
    end

    matcher :consent_view do |view_key, conditions|
      chain :to do |*context|
        @context = context
      end

      match do |subject_key|
        Consent.find_subjects(subject_key).any? do |subject|
          subject.views[view_key]&.conditions(*@context).eql?(conditions)
        end
      end

      failure_message do |subject_key|
        message = format(
          'expected %<skey>s (%<sclass>s) to provide view %<view>s with` \
          `%<conditions>p, but',
          skey: subject_key.to_s, sclass: subject.class,
          view: view_key, conditions: conditions
        )

        found_conditions = Consent.find_subjects(subject_key).map do |subject|
          subject.views[view_key]&.conditions(*@context)
        end.compact
        if found_conditions
          format(
            '%<message>s conditions are %<conditions>p',
            message: message, conditions: found_conditions
          )
        else
          actual_views = Consent.find_subjects(subject_key)
                                .map(&:views)
                                .map(&:keys).flatten
          format(
            '%<message>s available views are %<views>p',
            message: message, views: actual_views
          )
        end
      end
    end
  end
end
