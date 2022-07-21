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
end
