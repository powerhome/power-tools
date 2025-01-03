# frozen_string_literal: true

require "spec_helper"

RSpec.describe Consent::DSL do
  let(:subject) { Consent::Subject.new(nil, nil) }
  let(:defaults) { {} }
  let(:dsl) { Consent::DSL.new(subject, defaults) }

  describe ".build" do
    it "builds the subject through the DSL" do
      context_object = nil

      Consent::DSL.build subject do
        context_object = self
      end

      expect(context_object).to be_a(Consent::DSL)
    end

    it "builds defines the defaults" do
      context_defaults = nil

      Consent::DSL.build subject, default: :whatever do
        context_defaults = @defaults
      end

      expect(context_defaults).to eql(default: :whatever)
    end
  end

  describe "#view" do
    it "adds a view to the subject" do
      dsl.view :view_key, "View YEY"

      expect(subject.views[:view_key].label).to eql "View YEY"
    end

    it "accepts a block for conditions" do
      dsl.view :view_key, "View YEY" do |user|
        { id: user.id }
      end

      user = double(id: 10)
      expect(subject.views[:view_key].conditions(user)).to eql(id: user.id)
    end
  end

  describe "#action" do
    let(:view_all) { double }
    let(:view_no_access) { double }
    before do
      subject.views[:all] = view_all
      subject.views[:no_access] = view_no_access
    end

    it "creates the action in the subject" do
      dsl.action :action_key, "ACTIONNNNNN"

      expect(subject.actions.last.label).to eql "ACTIONNNNNN"
    end

    it "creates the action with views" do
      dsl.action :action_key, "ACTIONNNNNN", views: [:all]

      expect(subject.actions.last.views.keys).to eql [:all]
    end

    it "creates the action in the with context defaults" do
      defaults[:views] = [:all]

      dsl.action :action_key, "ACTIONNNNNN"

      expect(subject.actions.last.views.keys).to eql [:all]
    end

    it "allows to override defaults" do
      defaults[:views] = [:all]

      dsl.action :action_key, "ACTIONNNNNN", views: [:no_access]

      expect(subject.actions.last.views.keys).to eql [:no_access]
    end
  end

  describe "#with_defaults" do
    it "creates a new DSL context with merged defaults" do
      defaults[:foo] = "bar"

      block = ->(*) {}
      expected_defaults = { lol: "rofl", foo: "bar" }
      expect(Consent::DSL).to receive(:build)
        .with(subject, expected_defaults, &block)

      dsl.with_defaults lol: "rofl", &block
    end
  end
end
