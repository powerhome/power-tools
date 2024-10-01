# frozen_string_literal: true

require "spec_helper"

describe Consent::ModelAdditions do
  describe ".accessible_through" do
    let!(:information_tech) { ExampleDepartment.create! name: "IT" }
    let!(:developer) { ExampleRole.create! name: "Developer", example_department: information_tech }
    let!(:manager) { ExampleRole.create! name: "Manager" }
    let!(:director) { ExampleRole.create! name: "Director" }
    let!(:omega) do
      ExampleModel.create! name: "Omega Quadrant", example_role_id: manager.id, additional_role_id: developer.id
    end
    let!(:delta) do
      ExampleModel.create! name: "Delta Quadrant", example_role_id: developer.id, additional_role_id: manager.id
    end
    let!(:alpha) do
      ExampleModel.create! name: "Alpha Quadrant", example_role_id: manager.id, additional_role_id: developer.id
    end
    let!(:rim) { ExampleModel.create! name: "Outer Rim", example_role_id: developer.id, additional_role_id: manager.id }

    let(:role_report_permission) do
      Consent::Permission.new(subject: ExampleModel, action: :report, view: :role)
    end

    let(:user) { double(role_id: developer.id, secondary_role_id: director.id) }
    let(:ability) { Consent::Ability.new(user, permissions: [role_report_permission]) }

    it "allows full access for a system super" do
      super_user = double(:super_user)
      ability = Consent::Ability.new(super_user, super_user: true)

      expect(ExampleRole.accessible_through(ability, :report, ExampleModel)).to match_array ExampleRole.all
    end

    it "allows overriding the relation" do
      expect(ExampleRole.accessible_through(ability, :report, ExampleModel, relation: nil)).to match_array [developer]
      expect(ExampleRole.accessible_through(ability, :report, ExampleModel,
                                            relation: :additional_role)).to match_array [developer]
    end

    it "allows full access for a user with no restrictions" do
      ability.consent action: :report, subject: ExampleModel

      expect(ExampleRole.accessible_through(ability, :report, ExampleModel)).to match_array(ExampleRole.all)
    end

    it "supports subject/action pair as argument" do
      expect(ExampleRole.accessible_through(ability, "example_model/report")).to match_array([developer])
    end

    it "allows nested relations" do
      ability.consent action: :report, subject: ExampleModel, view: :role_department

      expect(ExampleDepartment.accessible_through(
               ability, :report, ExampleModel, relation: %i[example_role example_department]
             )).to match_array([information_tech])
    end

    it "allows querying through symbol subjects" do
      ability.consent action: :report_3d, subject: :beta, view: :role

      expect(ExampleRole.accessible_through(ability, :report_3d, :beta)).to match_array([developer])
    end

    describe "when the user has multiple permission sets" do
      it "will be permitted the on the union of both sets" do
        ability.consent subject: ExampleModel, action: :report, view: :secondary_role

        expect(ExampleRole.accessible_through(ability, :report, ExampleModel)).to match_array([developer, director])
      end
    end
  end
end
