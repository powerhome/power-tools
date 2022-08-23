# frozen_string_literal: true

require "rails_helper"

RSpec.describe Consent::Ability do
  let(:permissions) do
    [
      ::Consent::Permission.new(subject: ExampleModel, action: :update, view: "1"),
      ::Consent::Permission.new(subject: ExampleModel, action: :report, view: :lol),
    ]
  end
  let(:user) { double(id: 1) }

  it "it authorizes symbol permissions" do
    ability = Consent::Ability.new(user)

    ability.consent subject: :beta, action: :lol_til_death

    expect(ability).to be_able_to(:lol_til_death, :beta)
  end

  it "it authorizes model permissions" do
    ability = Consent::Ability.new(user)

    ability.consent subject: ExampleModel, action: :update

    expect(ability).to be_able_to(:update, ExampleModel)
    expect(ability).to be_able_to(:update, ExampleModel.new)
  end

  it "adds view conditions to cancan conditions" do
    ability = Consent::Ability.new(user)

    ability.consent subject: ExampleModel, action: :report, view: :lol

    expect(ability).to be_able_to(:report, ExampleModel)
    expect(ability).to be_able_to(:report, ExampleModel.new(name: "lol"))
    expect(ability).to_not be_able_to(:report, ExampleModel.new(name: "nop"))
  end

  it "does not apply default permissions when apply_defaults is set to false" do
    ability = Consent::Ability.new(nil, apply_defaults: false)

    expect(ability.permissions[:can]).to be_empty
    expect(ability.permissions[:cannot]).to be_empty
  end

  it "has the default view consented when defined" do
    ability = Consent::Ability.new(user, apply_defaults: true)

    past = ExampleModel.new(created_at: 10.days.ago)
    future = ExampleModel.new(created_at: 10.days.from_now)
    expect(ability).to be_able_to(:destroy, future)
    expect(ability).to_not be_able_to(:destroy, past)
  end

  it "cannot perform action when instance condition forbids" do
    ability = Consent::Ability.new(user)
    past = ExampleModel.new(created_at: 10.days.ago)

    expect(ability).to_not be_able_to(:destroy, past)
  end

  it "contextualizes the view/action in the subject definition" do
    ability = Consent::Ability.new(user)

    ability.consent subject: ExampleModel, action: :create, view: :lol
    ability.consent subject: ExampleModel, action: :destroy, view: :lol

    create_rule = ability.send(:relevant_rules, :create, ExampleModel).first
    destroy_rule = ability.send(:relevant_rules, :destroy, ExampleModel).first

    expect(create_rule.conditions).to eql(name: "ROFL")
    expect(destroy_rule.conditions).to eql(name: "lol")
  end

  it "can manage all when super_user is set to true" do
    ability = Consent::Ability.new(nil, super_user: true)

    expect(ability).to be_able_to(:manage, :all)
  end

  it "applies permissions from all given permissions" do
    ability = Consent::Ability.new(user, permissions: permissions)

    expect(ability).to be_able_to(:update, ExampleModel.new(name: "John"))
    expect(ability).to be_able_to(:report, ExampleModel.new(name: "lol"))
    expect(ability).to_not be_able_to(:report, ExampleModel.new(name: "John"))
  end

  describe "#can?" do
    it "allows to check for a permission using a string representation of it" do
      ability = Consent::Ability.new(user, permissions: permissions)

      expect(ability).to be_able_to("example_model/report")
      expect(ability).to be_able_to("example_model/update")
      expect(ability).to_not be_able_to("example_model/create")
    end
  end

  describe "#to_h" do
    it "maps the given to_h to the their ability" do
      ability = Consent::Ability.new(user, permissions: permissions)

      hash = ability.to_h([
                            "example_model/report",
                            "example_model/update",
                            "example_model/create",
                          ])
      expect(hash).to eql({
                            "example_model/report" => true,
                            "example_model/update" => true,
                            "example_model/create" => false,
                          })
    end
  end
end
