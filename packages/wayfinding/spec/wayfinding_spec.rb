# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wayfinding do
  def register_home(**overrides)
    defaults = { name: :home, engine: -> { FakeEngine }, helper: :home_path }

    described_class.register(**defaults, **overrides)
  end

  describe ".path_for" do
    it "forwards positional and keyword arguments to the helper" do
      register_home

      expect(described_class.path_for(:home, 17, current_tab: "Projects"))
        .to eq("/homes/17?current_tab=Projects")
    end

    it "accepts a Rack-callable engine constant as well as a lambda" do
      register_home(engine: FakeEngine)

      expect(described_class.path_for(:home, 17)).to eq("/homes/17")
    end

    it "raises for an unregistered destination, listing what is registered" do
      register_home
      described_class.register(name: :lead_source, engine: -> { FakeEngine }, helper: :lead_source_path)

      expect { described_class.path_for(:hone) }
        .to raise_error(Wayfinding::UnregisteredDestination, /No destination registered for :hone.*home, lead_source/m)
    end
  end

  describe ".url_for" do
    it "derives the url helper from the path helper" do
      register_home

      expect(described_class.url_for(:home, 17, current_tab: "Projects"))
        .to eq("https://nitro.test/homes/17?current_tab=Projects")
    end

    it "raises when the destination was registered with a block" do
      described_class.register(name: :home, engine: -> { FakeEngine }) { |home| home_path(home) }

      expect { described_class.url_for(:home, 17) }
        .to raise_error(Wayfinding::Error, /url is only derivable from `helper:`/)
    end

    it "raises when the helper does not end in _path" do
      register_home(helper: :legacy_home)

      expect { described_class.url_for(:home) }
        .to raise_error(Wayfinding::Error, /does not end in `_path`/)
    end
  end

  describe ".register" do
    it "overwrites a previous registration of the same name" do
      register_home
      register_home(helper: :legacy_home)

      expect(described_class.path_for(:home)).to eq("/legacy_home")
      expect(described_class.registered_names).to eq(%i[home])
    end

    it "raises when neither a helper nor a block is given" do
      expect { described_class.register(name: :home, engine: -> { FakeEngine }) }
        .to raise_error(Wayfinding::InvalidDestination, /declares neither `helper:` nor a block/)
    end

    it "raises when both a helper and a block are given" do
      expect { described_class.register(name: :home, engine: -> { FakeEngine }, helper: :home_path) { "/x" } }
        .to raise_error(Wayfinding::InvalidDestination, /declares both `helper:` and a block/)
    end

    it "raises when a helper is given without an engine" do
      expect { described_class.register(name: :home, helper: :home_path) }
        .to raise_error(Wayfinding::InvalidDestination, /declares `helper:` without an `engine:`/)
    end

    it "raises when action is given without subject" do
      expect { register_home(action: :read) }
        .to raise_error(Wayfinding::InvalidDestination, /`action:` without `subject:`/)
    end

    it "raises when subject is given without action" do
      expect { register_home(subject: -> { Object }) }
        .to raise_error(Wayfinding::InvalidDestination, /`subject:` without `action:`/)
    end
  end

  describe ".registered?" do
    it "reports registration by name" do
      register_home

      expect(described_class).to be_registered(:home)
      expect(described_class).not_to be_registered(:nope)
    end
  end

  describe ".verify!" do
    it "passes when every expected destination is registered" do
      register_home

      expect(described_class.verify!(%i[home])).to be(true)
    end

    it "raises listing exactly the missing destinations" do
      register_home

      expect { described_class.verify!(%i[home lead_source project]) }
        .to raise_error(Wayfinding::UnregisteredDestination, "Missing destination registrations: lead_source, project")
    end
  end

  describe ".preserve!" do
    it "restores the registry afterwards" do
      register_home

      described_class.preserve! do
        described_class.register(name: :temporary, engine: -> { FakeEngine }, helper: :legacy_home)
        expect(described_class.registered_names).to eq(%i[home temporary])
      end

      expect(described_class.registered_names).to eq(%i[home])
    end

    it "restores the registry even when the block raises" do
      register_home

      expect do
        described_class.preserve! do
          described_class.register(name: :temporary, engine: -> { FakeEngine }, helper: :legacy_home)
          raise "boom"
        end
      end.to raise_error("boom")

      expect(described_class.registered_names).to eq(%i[home])
    end

    it "restores kind definitions afterwards" do
      described_class.preserve! do
        described_class.define_kind(:report, requires: %i[label])
      end

      expect(described_class.kinds).to be_empty
    end
  end
end
