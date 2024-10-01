# frozen_string_literal: true

RSpec.describe ScimShady::QueryBuilder do
  subject { ScimShady::QueryBuilder.new(model: Group) }

  it "queries the given model with the given options" do
    subject.options[:filter] = "displayName eq Admin"

    allow(ScimShady.client).to receive(:perform_request) { {} }

    subject.to_a

    expect(ScimShady.client).to(
      have_received(:perform_request)
        .with(method: :Get,
          path: "Groups",
          list: Group,
          query: {filter: "displayName eq Admin"})
    )
  end

  describe "#attributes" do
    it "builds a query requesting only the given attributes" do
      query = subject.attributes(:id, :displayName)

      expect(query.options[:attributes]).to eql "id,displayName"
    end

    it "replaces previously set attributes" do
      query = subject.attributes(:id, :displayName)
        .attributes(:displayName)

      expect(query.options[:attributes]).to eql "displayName"
    end
  end

  describe "#filter" do
    it "builds a query with the given filter" do
      query = subject.filter('displayName eq "John"')

      expect(query.options[:filter]).to eql 'displayName eq "John"'
    end

    it "amends the previously set filter with AND" do
      query = subject.filter('displayName eq "John"')
        .filter("active eq true")

      expect(query.options[:filter]).to eql 'displayName eq "John" AND active eq true'
    end
  end

  describe "#pluck" do
    it "queries only the given attributes and return their values" do
      ScimShady.client.mock(
        method: :Get,
        path: "Groups",
        query: {attributes: "id,displayName"},
        fixture: "Get-Groups.json"
      )

      result = subject.pluck(:id, :displayName)

      expect(result).to match_array [
        [2986, "Admin"],
        [2998, "bi"]
      ]
    end
  end

  describe "#all" do
    it "is an enum of all entries in all pages" do
      ScimShady.client.mock(
        method: :Get,
        path: "Groups",
        query: {},
        fixture: "Get-Groups.json"
      )
      ScimShady.client.mock(
        method: :Get,
        path: "Groups",
        query: {startIndex: 3},
        fixture: "Get-Groups-page2.json"
      )

      all_groups = subject.all.to_a

      expect(all_groups.size).to eql 4
      expect(all_groups.map(&:displayName)).to match_array ["Admin", "Emperors", "Master of the Universe", "bi"]
      expect(all_groups.map(&:externalId)).to match_array ["200000", "300000", "700000", "77217"]
    end
  end
end
