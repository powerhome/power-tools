# frozen_string_literal: true

require "spec_helper"

RSpec.describe AuditTracker do
  describe "relationships", type: :model do
    let(:lead) { Internal::Lead.new }
    let(:sale) { Internal::Sale.new }
    let(:score) { Internal::Score.new }
    let(:home) { Internal::Home.new }

    it "sets up 'create' relationships for all trackers" do
      expect(lead).to belong_to(:created_by).class_name("::Internal::User")
      expect(lead).to belong_to(:created_by_department).class_name("::Internal::Department")
    end

    it "sets up 'update' relationships for all trackers" do
      expect(lead).to belong_to(:updated_by).class_name("::Internal::User")
      expect(lead).to belong_to(:updated_by_department).class_name("::Internal::Department")
    end

    it "is does not create relationships when columns don't exist" do
      expect(sale).to belong_to(:updated_by)
      expect(sale).to_not belong_to(:created_by)
      expect(sale).to_not belong_to(:updated_by_department)
      expect(sale).to_not belong_to(:created_by_department)
    end

    it "is does not create relationships when the tracker is disabled" do
      expect(home).to belong_to(:updated_by)
      expect(home).to belong_to(:created_by)
      expect(home).to_not belong_to(:updated_by_department)
      expect(home).to_not belong_to(:created_by_department)
    end

    it "does not override existing relationships" do
      expect(score).to belong_to(:created_by).class_name("::Internal::ManagerUser")
    end

    it "allows to override relation options" do
      expect(score).to belong_to(:updated_by).class_name("::Internal::ManagerUser")
    end
  end

  describe "data tracking" do
    let(:marketing) { Internal::Department.create(name: "Marketing") }
    let(:steve) do
      Internal::User.create(
        name: "Stephen Doe",
        department: marketing
      )
    end
    let(:sales) { Internal::Department.create(name: "Sales") }
    let(:john) do
      Internal::User.create(
        name: "John Doe",
        department: sales
      )
    end

    it "tracks the data on create" do
      Internal::Current.user = john
      created_lead = Internal::Lead.create

      expect(created_lead.created_by).to eql john
      expect(created_lead.created_by_department).to eql sales
    end

    it "tracks updates relationships on create" do
      Internal::Current.user = john
      created_lead = Internal::Lead.create

      expect(created_lead.updated_by).to eql john
      expect(created_lead.updated_by_department).to eql sales
    end

    it "tracks the data on update" do
      Internal::Current.user = steve
      created_lead = Internal::Lead.create

      Internal::Current.user = john
      created_lead.update(strength: 100)

      expect(created_lead.created_by).to eql steve
      expect(created_lead.created_by_department).to eql marketing
      expect(created_lead.updated_by).to eql john
      expect(created_lead.updated_by_department).to eql sales
    end

    it "does not track data when the model does not have the required column" do
      Internal::Current.user = steve
      created_sale = Internal::Sale.create

      Internal::Current.user = john
      created_sale.update(price: 100_000)

      expect(created_sale.updated_by).to eql john
    end

    it "is does not create relationships when the tracker is disabled" do
      Internal::Current.user = steve
      created_home = Internal::Home.create

      Internal::Current.user = john
      created_home.update(price: 200_000)

      expect(created_home.created_by).to eql steve
      expect(created_home.updated_by).to eql john
    end

    it "tracks data with the given overrides" do
      Internal::Current.user = steve
      created_score = Internal::Score.create

      Internal::Current.user = john
      created_score.update(score: 10)

      expect(created_score.created_by).to eql Internal::ManagerUser.find(steve.id)
      expect(created_score.updated_by).to eql Internal::ManagerUser.find(john.id)
    end

    it "does not overwrite values manually set" do
      Internal::Current.user = steve
      created_home = Internal::Home.create(created_by: john, updated_by: john)

      Internal::Current.user = john
      created_home.update(price: 100_00, updated_by: steve)

      expect(created_home.created_by).to eql john
      expect(created_home.updated_by).to eql steve
    end
  end
end
