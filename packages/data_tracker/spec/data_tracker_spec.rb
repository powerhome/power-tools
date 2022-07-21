# frozen_string_literal: true

RSpec.describe DataTracker do
  before do
    DataTracker.setup do
      tracker(:user) do
        create :created_by, foreign_key: :created_by_id, class_name: "::Internal::User"
        update :updated_by, foreign_key: :updated_by_id, class_name: "::Internal::User"
        value { Internal::Current.user }
      end

      tracker(:department) do
        create :created_by_department, foreign_key: :created_by_department_id, class_name: "::Internal::Department"
        update :updated_by_department, foreign_key: :updated_by_department_id, class_name: "::Internal::Department"
        value { Internal::Current.user&.department }
      end
    end
  end

  after do
    DataTracker.trackers.clear
  end

  describe "relationships", type: :model do
    let(:lead) { ::Internal::Lead.new }
    let(:sale) { ::Internal::Sale.new }

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
      expect(sale).to belong_to(:created_by)
      expect(sale).to_not belong_to(:updated_by_department)
      expect(sale).to_not belong_to(:created_by_department)
    end
  end

  describe "data tracking" do
    let(:marketing) { ::Internal::Department.create(name: "Marketing") }
    let(:steve) do
      ::Internal::User.create(
        name: "Stephen Doe",
        department: marketing
      )
    end
    let(:sales) { ::Internal::Department.create(name: "Sales") }
    let(:john) do
      ::Internal::User.create(
        name: "John Doe",
        department: sales
      )
    end

    it "tracks the data on create" do
      ::Internal::Current.user = john
      created_lead = ::Internal::Lead.create

      expect(created_lead.created_by).to eql john
      expect(created_lead.created_by_department).to eql sales
    end

    it "tracks the data on update" do
      ::Internal::Current.user = steve
      created_lead = ::Internal::Lead.create

      ::Internal::Current.user = john
      created_lead.update(strength: 100)

      expect(created_lead.created_by).to eql steve
      expect(created_lead.created_by_department).to eql marketing
      expect(created_lead.updated_by).to eql john
      expect(created_lead.updated_by_department).to eql sales
    end

    it "does not track data when the model does not have the required column" do
      ::Internal::Current.user = steve
      created_sale = ::Internal::Sale.create

      ::Internal::Current.user = john
      created_sale.update(price: 100_000)

      expect(created_sale.created_by).to eql steve
      expect(created_sale.updated_by).to eql john
    end
  end
end
