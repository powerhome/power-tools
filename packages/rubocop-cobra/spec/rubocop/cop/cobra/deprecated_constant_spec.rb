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
        has_many :regions, class_name: "Territory"
                                       ^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
        belongs_to :home_region, class_name: '::Territory', optional: true
                                             ^^^^^^^^^^^^^ Use `Directory::Territory` instead of the deprecated `Territory`.
      RUBY

      expect_correction(<<~RUBY)
        has_many :regions, class_name: "Directory::Territory"
        belongs_to :home_region, class_name: 'Directory::Territory', optional: true
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
        "Directory::Title".safe_constantize
      RUBY
    end

    it "does not register an offense for a class_name Rails resolves inside the model's namespace" do
      expect_no_offenses(<<~RUBY)
        module Directory
          class Branch < ApplicationRecord
            belongs_to :region, class_name: "Territory"
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
  end
end
