# frozen_string_literal: true

RSpec.describe ScimShady::ListResponse do
  describe "object enumerator" do
    let(:response_json) { fixture_json("Get-Groups.json") }
    subject { ScimShady::ListResponse.new(response_json, Group) }

    it "initializes each resource as a model" do
      expect(subject.first).to be_a Group
    end
  end

  describe "#has_more_pages?" do
    it "has more pages when last index is over the total results" do
      list = ScimShady::ListResponse.new(
        {
          "totalResults" => 4,
          "startIndex" => 1,
          "itemsPerPage" => 2
        },
        nil
      )

      expect(list).to have_more_pages
    end

    it "has more pages when last index is the same as the total results" do
      list = ScimShady::ListResponse.new(
        {
          "totalResults" => 100,
          "startIndex" => 80,
          "itemsPerPage" => 20
        },
        nil
      )

      expect(list).to have_more_pages
    end

    it "does not have more pages when last index is over the total results" do
      list = ScimShady::ListResponse.new(
        {
          "totalResults" => 100,
          "startIndex" => 99,
          "itemsPerPage" => 20
        },
        nil
      )

      expect(list).to_not have_more_pages
    end
  end

  describe "#start_index" do
    it "Is the startIndex attribute of the json" do
      list = ScimShady::ListResponse.new({"startIndex" => 80}, nil)

      expect(list.start_index).to eql 80
    end
  end

  describe "#per_page" do
    it "Is the itemsPerPage attribute of the json" do
      list = ScimShady::ListResponse.new({"itemsPerPage" => 20}, nil)

      expect(list.per_page).to eql 20
    end
  end

  describe "#total_results" do
    it "Is the totalResults attribute of the json" do
      list = ScimShady::ListResponse.new({"totalResults" => 20}, nil)

      expect(list.total_results).to eql 20
    end
  end

  describe "#next_index" do
    it "current starting index plus all items on the page" do
      list = ScimShady::ListResponse.new({"startIndex" => 20, "itemsPerPage" => 20}, nil)

      expect(list.next_index).to eql 40
    end
  end
end
