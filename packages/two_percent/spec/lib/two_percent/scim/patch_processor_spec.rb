# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoPercent::Scim::PatchProcessor do
  describe "#initialize" do
    it "parses valid PATCH request with Operations array" do
      patch_request = {
        schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"],
        Operations: [
          { op: "replace", path: "displayName", value: "New Name" },
        ],
      }

      processor = described_class.new(patch_request)
      expect(processor.operations).to be_an(Array)
      expect(processor.operations.size).to eq(1)
    end

    it "raises error when Operations array is missing" do
      invalid_request = { schemas: ["urn:ietf:params:scim:api:messages:2.0:PatchOp"] }

      expect do
        described_class.new(invalid_request)
      end.to raise_error(ArgumentError, "PATCH request must contain 'Operations' array")
    end

    it "raises error when Operations is not an array" do
      invalid_request = { Operations: "not-an-array" }

      expect do
        described_class.new(invalid_request)
      end.to raise_error(ArgumentError, "PATCH request must contain 'Operations' array")
    end
  end

  describe "#apply_to_hash" do
    let(:original_hash) do
      {
        "schemas" => ["urn:ietf:params:scim:schemas:core:2.0:User"],
        "id" => "user-123",
        "externalId" => "ext-123",
        "userName" => "john.doe@example.com",
        "displayName" => "John Doe",
        "emails" => [
          { "value" => "john@example.com", "type" => "work", "primary" => true },
        ],
        "active" => true,
      }
    end

    describe "replace operation" do
      it "replaces a simple attribute" do
        patch_request = {
          Operations: [
            { op: "replace", path: "displayName", value: "Jane Doe" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["displayName"]).to eq("Jane Doe")
        expect(result["userName"]).to eq("john.doe@example.com") # Unchanged
      end

      it "replaces a nested attribute" do
        hash_with_nested = original_hash.merge(
          "name" => { "givenName" => "John", "familyName" => "Doe" }
        )

        patch_request = {
          Operations: [
            { op: "replace", path: "name.givenName", value: "Jane" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(hash_with_nested)

        expect(result["name"]["givenName"]).to eq("Jane")
        expect(result["name"]["familyName"]).to eq("Doe") # Unchanged
      end

      it "replaces boolean value" do
        patch_request = {
          Operations: [
            { op: "replace", path: "active", value: false },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["active"]).to be false
      end

      it "replaces with nil value" do
        patch_request = {
          Operations: [
            { op: "replace", path: "externalId", value: nil },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["externalId"]).to be_nil
      end

      it "handles replace without path (replaces root attributes)" do
        patch_request = {
          Operations: [
            { op: "replace", value: { "displayName" => "New Name", "userName" => "new.user@example.com" } },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["displayName"]).to eq("New Name")
        expect(result["userName"]).to eq("new.user@example.com")
        expect(result["id"]).to eq("user-123") # Other attributes preserved
      end
    end

    describe "add operation" do
      it "adds a new attribute" do
        patch_request = {
          Operations: [
            { op: "add", path: "nickName", value: "Johnny" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["nickName"]).to eq("Johnny")
      end

      it "adds to an array by appending value" do
        patch_request = {
          Operations: [
            { op: "add", path: "emails", value: [{ "value" => "jane@example.com", "type" => "home" }] },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["emails"].size).to eq(2)
        expect(result["emails"].last["value"]).to eq("jane@example.com")
      end

      it "creates nested path if it doesn't exist" do
        patch_request = {
          Operations: [
            { op: "add", path: "address.streetAddress", value: "123 Main St" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["address"]).to be_a(Hash)
        expect(result["address"]["streetAddress"]).to eq("123 Main St")
      end

      it "handles add without path (merges into root)" do
        patch_request = {
          Operations: [
            { op: "add", value: { "nickName" => "Johnny", "title" => "Manager" } },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["nickName"]).to eq("Johnny")
        expect(result["title"]).to eq("Manager")
      end
    end

    describe "remove operation" do
      it "removes an attribute" do
        patch_request = {
          Operations: [
            { op: "remove", path: "externalId" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result).not_to have_key("externalId")
        expect(result["userName"]).to eq("john.doe@example.com") # Others unchanged
      end

      it "removes a nested attribute" do
        hash_with_nested = original_hash.merge(
          "name" => { "givenName" => "John", "familyName" => "Doe", "middleName" => "M" }
        )

        patch_request = {
          Operations: [
            { op: "remove", path: "name.middleName" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(hash_with_nested)

        expect(result["name"]).not_to have_key("middleName")
        expect(result["name"]["givenName"]).to eq("John") # Others unchanged
      end

      it "handles remove without path (no-op)" do
        patch_request = {
          Operations: [
            { op: "remove" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result).to eq(original_hash) # Unchanged
      end
    end

    describe "multiple operations" do
      it "applies operations in order" do
        patch_request = {
          Operations: [
            { op: "replace", path: "displayName", value: "Jane Doe" },
            { op: "add", path: "nickName", value: "Janey" },
            { op: "remove", path: "externalId" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["displayName"]).to eq("Jane Doe")
        expect(result["nickName"]).to eq("Janey")
        expect(result).not_to have_key("externalId")
      end

      it "handles operations that depend on previous operations" do
        patch_request = {
          Operations: [
            { op: "add", path: "name.givenName", value: "Jane" },
            { op: "add", path: "name.familyName", value: "Smith" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["name"]["givenName"]).to eq("Jane")
        expect(result["name"]["familyName"]).to eq("Smith")
      end
    end

    describe "operation with Hash value (flattening)" do
      it "flattens nested value hash into multiple operations" do
        patch_request = {
          Operations: [
            {
              op: "replace",
              value: {
                "displayName" => "New Name",
                "userName" => "new.user@example.com",
              },
            },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["displayName"]).to eq("New Name")
        expect(result["userName"]).to eq("new.user@example.com")
      end

      it "flattens nested value hash with path" do
        patch_request = {
          Operations: [
            {
              op: "replace",
              path: "name",
              value: {
                "givenName" => "Jane",
                "familyName" => "Smith",
              },
            },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["name"]["givenName"]).to eq("Jane")
        expect(result["name"]["familyName"]).to eq("Smith")
      end
    end

    describe "unknown operation" do
      it "raises error for unknown operation type" do
        patch_request = {
          Operations: [
            { op: "invalid", path: "displayName", value: "Test" },
          ],
        }

        processor = described_class.new(patch_request)

        expect do
          processor.apply_to_hash(original_hash)
        end.to raise_error(ArgumentError, "Unknown PATCH operation: invalid")
      end
    end

    describe "immutability" do
      it "does not modify the original hash" do
        original_copy = original_hash.dup

        patch_request = {
          Operations: [
            { op: "replace", path: "displayName", value: "Modified Name" },
          ],
        }

        processor = described_class.new(patch_request)
        processor.apply_to_hash(original_hash)

        expect(original_hash).to eq(original_copy)
      end
    end

    describe "symbol vs string keys" do
      it "handles operations with string keys" do
        patch_request = {
          Operations: [
            { "op" => "replace", "path" => "displayName", "value" => "New Name" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["displayName"]).to eq("New Name")
      end

      it "handles mixed string/symbol keys in patch request" do
        patch_request = {
          Operations: [
            { "op" => "replace", :path => "displayName", "value" => "New Name" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["displayName"]).to eq("New Name")
      end
    end

    describe "edge cases" do
      it "handles empty operations array" do
        patch_request = { Operations: [] }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result).to eq(original_hash)
      end

      it "handles deeply nested paths" do
        complex_hash = {
          "level1" => {
            "level2" => {
              "level3" => {
                "value" => "deep",
              },
            },
          },
        }

        patch_request = {
          Operations: [
            { op: "replace", path: "level1.level2.level3.value", value: "very deep" },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(complex_hash)

        expect(result["level1"]["level2"]["level3"]["value"]).to eq("very deep")
      end

      it "handles numeric values" do
        patch_request = {
          Operations: [
            { op: "add", path: "age", value: 30 },
          ],
        }

        processor = described_class.new(patch_request)
        result = processor.apply_to_hash(original_hash)

        expect(result["age"]).to eq(30)
      end
    end
  end
end
