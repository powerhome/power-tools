# frozen_string_literal: true

RSpec.describe ScimShady::ResourceQuery do
  describe ".resource_path" do
    it "is the title case plural form of the class name" do
      expect(User.resource_path).to eql "Users"
      expect(Group.resource_path).to eql "Groups"
    end
  end

  describe ".find" do
    it "fetches a resource by id" do
      ScimShady.client.mock(
        method: :Get,
        path: "Users/123",
        fixture: "user-resource.json"
      )

      obj = User.find(123)

      expect(obj.id).to eql 123
    end

    it "initializes an unchanged object" do
      ScimShady.client.mock(
        method: :Get,
        path: "Users/123",
        fixture: "user-resource.json"
      )

      obj = User.find(123)

      expect(obj).to_not be_changed
    end
  end

  describe ".query(**)" do
    it "is a query builder for the current model" do
      expect(User.query).to be_a ScimShady::QueryBuilder
      expect(User.query).to have_attributes(model: User)
    end

    it "initializes the query builder with the given options" do
      expect(User.query(filter: "name eq John")).to have_attributes(options: {filter: "name eq John"})
    end
  end
end
