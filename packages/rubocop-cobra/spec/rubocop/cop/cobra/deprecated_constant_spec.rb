# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Cobra::DeprecatedConstant, :config do
  let(:cop_config) do
    {
      "Constants" => {
        "Territory" => "Directory::Territory",
        "UserTitle" => "::Directory::Title",
        "CoreModels::Region" => "Directory::Region",
      },
    }
  end

  context "without any configured constants" do
    let(:cop_config) { {} }

    it "registers no offenses" do
      expect_no_offenses(<<~RUBY)
        Territory.find(1)
        belongs_to :territory
      RUBY
    end
  end

  context "with constant references" do
    it "registers an offense and corrects a relative reference" do
      expect_offense(<<~RUBY)
        Territory.find(1)
        ^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
      RUBY

      expect_correction(<<~RUBY)
        Directory::Territory.find(1)
      RUBY
    end

    it "registers an offense and corrects an absolute reference, keeping it absolute" do
      expect_offense(<<~RUBY)
        ::Territory::STATUSES
        ^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
      RUBY

      expect_correction(<<~RUBY)
        ::Directory::Territory::STATUSES
      RUBY
    end

    it "accepts a replacement written with a leading ::" do
      expect_offense(<<~RUBY)
        UserTitle.all
        ^^^^^^^^^ Use `Directory::Title` instead of the deprecated `UserTitle`.
      RUBY

      expect_correction(<<~RUBY)
        Directory::Title.all
      RUBY
    end

    it "registers an offense for a namespaced deprecated constant" do
      expect_offense(<<~RUBY)
        CoreModels::Region.first
        ^^^^^^^^^^^^^^^^^^ Use `Directory::Region` instead of the deprecated `CoreModels::Region`.
      RUBY

      expect_correction(<<~RUBY)
        Directory::Region.first
      RUBY
    end

    it "registers an offense in a superclass" do
      expect_offense(<<~RUBY)
        class SalesTerritory < Territory
                               ^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
        end
      RUBY
    end

    it "registers an offense inside a compact class definition, where Ruby does not search the outer namespace" do
      expect_offense(<<~RUBY)
        class Directory::Branch
          Territory.find(1)
          ^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
        end
      RUBY
    end

    it "does not register an offense for the replacement" do
      expect_no_offenses(<<~RUBY)
        Directory::Territory.find(1)
        ::Directory::Territory::STATUSES
        Other::Territory.find(1)
      RUBY
    end

    it "does not register an offense for the deprecated class's own definition" do
      expect_no_offenses(<<~RUBY)
        class Territory < Directory::Territory; end
        Region = Directory::Region
      RUBY
    end

    it "does not register an offense where Ruby already resolves the name to the replacement" do
      expect_no_offenses(<<~RUBY)
        module Directory
          class Branch < ApplicationRecord
            def territory_ids
              Territory.pluck(:id)
            end
          end
        end
      RUBY
    end
  end

  context "with string class names" do
    it "registers an offense and corrects class_name:" do
      expect_offense(<<~RUBY)
        has_many :territories, class_name: "Territory"
                                           ^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
        belongs_to :home_region, class_name: '::Territory', optional: true
                                             ^^^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
      RUBY

      expect_correction(<<~RUBY)
        has_many :territories, class_name: "Directory::Territory"
        belongs_to :home_region, class_name: '::Directory::Territory', optional: true
      RUBY
    end

    it "registers an offense and corrects constantize and safe_constantize" do
      expect_offense(<<~RUBY)
        "Territory".constantize
        ^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
        "::UserTitle".safe_constantize
        ^^^^^^^^^^^^^ Use `Directory::Title` instead of the deprecated `UserTitle`.
      RUBY

      expect_correction(<<~RUBY)
        "Directory::Territory".constantize
        "::Directory::Title".safe_constantize
      RUBY
    end

    it "does not register an offense for a class_name Rails resolves inside the model's namespace" do
      expect_no_offenses(<<~RUBY)
        module Directory
          class Branch < ApplicationRecord
            belongs_to :territory, class_name: "Territory"
          end
        end
      RUBY
    end

    it "does not register an offense for other strings" do
      expect_no_offenses(<<~RUBY)
        label = "Territory"
        where(owner_type: "Territory")
      RUBY
    end
  end

  context "with associations whose class Rails infers from the name" do
    it "registers an offense and adds class_name" do
      expect_offense(<<~RUBY)
        class Home < ApplicationRecord
          belongs_to :territory
          ^^^^^^^^^^^^^^^^^^^^^ `belongs_to :territory` resolves to the deprecated `Territory`. Name the replacement with `class_name: "Directory::Territory"`.
          has_many :territories, -> { order(:name) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `has_many :territories` resolves to the deprecated `Territory`. Name the replacement with `class_name: "Directory::Territory"`.
          has_one :user_title, inverse_of: :home, dependent: :destroy
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `has_one :user_title` resolves to the deprecated `UserTitle`. Name the replacement with `class_name: "Directory::Title"`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class Home < ApplicationRecord
          belongs_to :territory, class_name: "Directory::Territory"
          has_many :territories, -> { order(:name) }, class_name: "Directory::Territory"
          has_one :user_title, inverse_of: :home, dependent: :destroy, class_name: "Directory::Title"
        end
      RUBY
    end

    it "does not register an offense when the class is explicit or not inferred from the name" do
      expect_no_offenses(<<~RUBY)
        class Home < ApplicationRecord
          belongs_to :territory, class_name: "Directory::Territory"
          belongs_to :territory, polymorphic: true
          has_many :territories, through: :assignments
          has_many :branches
        end
      RUBY
    end

    it "does not register an offense in a model whose namespace holds the replacement" do
      expect_no_offenses(<<~RUBY)
        module Directory
          class Branch < ApplicationRecord
            belongs_to :territory
          end
        end

        class Directory::Office < Directory::ApplicationRecord
          has_many :territories
        end
      RUBY
    end

    it "skips serializer and resource classes, whose DSLs reuse the association names" do
      expect_no_offenses(<<~RUBY)
        class HomeSerializer < ActiveModel::Serializer
          belongs_to :territory
        end

        class BranchSerializer
          include JSONAPI::Serializer
          has_many :territories
        end

        class BranchResource < ApplicationResource
          belongs_to :territory
        end
      RUBY
    end

    it "registers an offense in a model whose name ends in Resource or Serializer" do
      expect_offense(<<~RUBY)
        class AdditionalResource < ApplicationRecord
          belongs_to :territory
          ^^^^^^^^^^^^^^^^^^^^^ `belongs_to :territory` resolves to the deprecated `Territory`. Name the replacement with `class_name: "Directory::Territory"`.
        end

        class StoredSerializer < ActiveRecord::Base
          has_many :territories
          ^^^^^^^^^^^^^^^^^^^^^ `has_many :territories` resolves to the deprecated `Territory`. Name the replacement with `class_name: "Directory::Territory"`.
        end
      RUBY
    end
  end

  context "with names relative to the deprecated constant's namespace" do
    it "registers an offense for references Ruby or Rails resolve to a namespaced deprecated constant" do
      expect_offense(<<~RUBY)
        module CoreModels
          class Office < ApplicationRecord
            belongs_to :region
            ^^^^^^^^^^^^^^^^^^ `belongs_to :region` resolves to the deprecated `CoreModels::Region`. Name the replacement with `class_name: "Directory::Region"`.
            has_one :home_region, class_name: "Region"
                                              ^^^^^^^^ Use `Directory::Region` instead of the deprecated `CoreModels::Region`.

            def region_ids
              Region.pluck(:id)
              ^^^^^^ Use `Directory::Region` instead of the deprecated `CoreModels::Region`.
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module CoreModels
          class Office < ApplicationRecord
            belongs_to :region, class_name: "Directory::Region"
            has_one :home_region, class_name: "Directory::Region"

            def region_ids
              Directory::Region.pluck(:id)
            end
          end
        end
      RUBY
    end

    it "follows Ruby's lexical lookup for a compact class and Rails' namespace lookup for its associations" do
      expect_offense(<<~RUBY)
        class CoreModels::Office < ApplicationRecord
          belongs_to :region
          ^^^^^^^^^^^^^^^^^^ `belongs_to :region` resolves to the deprecated `CoreModels::Region`. Name the replacement with `class_name: "Directory::Region"`.
          Region.first
        end
      RUBY
    end

    it "does not register an offense for unrelated namespaces or the top-level name" do
      expect_no_offenses(<<~RUBY)
        Region.first
        belongs_to :region

        module Sales
          class Office < ApplicationRecord
            belongs_to :region
            Region.first
          end
        end
      RUBY
    end
  end

  context "with associations in a concern" do
    it "registers an offense even inside the replacement's namespace, since the including model is unknown" do
      expect_offense(<<~RUBY)
        module Directory
          module HasTerritory
            extend ActiveSupport::Concern

            included do
              belongs_to :territory
              ^^^^^^^^^^^^^^^^^^^^^ `belongs_to :territory` resolves to the deprecated `Territory`. Name the replacement with `class_name: "Directory::Territory"`.
              has_many :territories, class_name: "Territory"
                                                 ^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
            end
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module Directory
          module HasTerritory
            extend ActiveSupport::Concern

            included do
              belongs_to :territory, class_name: "Directory::Territory"
              has_many :territories, class_name: "Directory::Territory"
            end
          end
        end
      RUBY
    end

    it "still leaves constant references to Ruby's lexical lookup" do
      expect_no_offenses(<<~RUBY)
        module Directory
          module HasTerritory
            def territory_ids
              Territory.pluck(:id)
            end
          end
        end
      RUBY
    end
  end

  context "with a same-named class in another namespace" do
    it "does not register an offense when the file defines the class Ruby or Rails finds first" do
      expect_no_offenses(<<~RUBY)
        module Sales
          class Territory < ApplicationRecord
            def self.active
              Territory.where(active: true)
            end
          end

          class Office < ApplicationRecord
            belongs_to :territory
            has_many :territories, class_name: "Territory"
          end
        end
      RUBY
    end

    it "registers an offense when the class is defined elsewhere, since the cop sees one file at a time" do
      expect_offense(<<~RUBY)
        module Sales
          Territory.find(1)
          ^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
        end
      RUBY
    end
  end

  context "with an acronym in the class name" do
    let(:cop_config) { { "Constants" => { "APIKey" => "Auth::APIKey" } } }

    it "matches the association Rails camelizes with the application's acronym" do
      expect_offense(<<~RUBY)
        class Account < ApplicationRecord
          has_many :api_keys
          ^^^^^^^^^^^^^^^^^^ `has_many :api_keys` resolves to the deprecated `APIKey`. Name the replacement with `class_name: "Auth::APIKey"`.
        end
      RUBY

      expect_correction(<<~RUBY)
        class Account < ApplicationRecord
          has_many :api_keys, class_name: "Auth::APIKey"
        end
      RUBY
    end

    it "matches constants and strings exactly, as Ruby does" do
      expect_no_offenses(<<~RUBY)
        class ZipImporter < ZipCodesUtil
          def parse(item)
            item.match?(APIKEY) || item.match?(ApiKey)
          end
        end
        "APIKEY".constantize
        has_many :keys, class_name: "ApiKey"
      RUBY
    end

    it "does not register an offense once Rails reaches the replacement" do
      expect_no_offenses(<<~RUBY)
        module Auth
          class Account < ApplicationRecord
            has_many :api_keys
          end
        end
      RUBY
    end
  end
end
