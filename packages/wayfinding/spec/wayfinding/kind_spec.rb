# frozen_string_literal: true

require "spec_helper"

RSpec.describe Wayfinding::Kind do
  def report_defaults
    {
      name: :installer_pay_report, kind: :report, engine: -> { FakeEngine },
      helper: :installer_pay_reports_path, action: :view_installer_pay_report,
      subject: -> { Object }, label: "Installer Pay Report", description: "Materials, equipment, labor"
    }
  end

  def register_report(**overrides)
    Wayfinding.register(**report_defaults, **overrides)
  end

  describe ".define_kind" do
    before { Wayfinding.define_kind(:report, requires: %i[label description action subject]) }

    it "accepts a destination carrying every required field" do
      expect { register_report }.not_to raise_error
    end

    it "raises naming the missing field" do
      expect { register_report(label: nil) }
        .to raise_error(Wayfinding::InvalidDestination, /missing required field: label/)
    end

    it "raises naming every missing field" do
      expect { register_report(label: nil, description: nil) }
        .to raise_error(Wayfinding::InvalidDestination, /missing required fields: label, description/)
    end

    it "raises when a destination declares an undefined kind" do
      expect { register_report(kind: :dashboard) }
        .to raise_error(Wayfinding::UnknownKind, /unknown kind :dashboard.*Defined: report/m)
    end
  end

  describe "arbitrary required fields" do
    before { Wayfinding.define_kind(:widget, requires: %i[foo bar]) }

    it "requires fields the gem gives no behavior to" do
      expect do
        Wayfinding.register(name: :thing, kind: :widget, engine: -> { FakeEngine }, helper: :legacy_home, foo: 1)
      end.to raise_error(Wayfinding::InvalidDestination, /missing required field: bar/)
    end

    it "accepts them when present, and reads them back" do
      Wayfinding.register(
        name: :thing, kind: :widget, engine: -> { FakeEngine }, helper: :legacy_home, foo: 1, bar: 2
      )

      expect(Wayfinding.fetch(:thing)[:bar]).to eq(2)
    end
  end

  describe "validation and laziness" do
    before { Wayfinding.define_kind(:report, requires: %i[subject action]) }

    it "asserts presence without resolving callables" do
      resolved = false

      expect do
        Wayfinding.register(
          name: :report_one, kind: :report, engine: -> { FakeEngine }, helper: :legacy_home,
          action: :view, subject: -> {
            resolved = true
            Object
          }
        )
      end.not_to raise_error

      expect(resolved).to be(false)
    end
  end

  describe "Wayfinding.of_kind" do
    before do
      Wayfinding.define_kind(:report, requires: %i[label])
      Wayfinding.register(name: :home, engine: -> { FakeEngine }, helper: :home_path)
      Wayfinding.register(
        name: :pay_report, kind: :report, engine: -> { FakeEngine }, helper: :installer_pay_reports_path,
        label: "Pay", action: :view_pay, subject: -> { Object }
      )
      Wayfinding.register(
        name: :margin_report, kind: :report, engine: -> { FakeEngine }, helper: :legacy_home,
        label: "Margin", action: :view_margin, subject: -> { Object }
      )
      Wayfinding.register(
        name: :unguarded_report, kind: :report, engine: -> { FakeEngine }, helper: :legacy_home, label: "Unguarded"
      )
    end

    it "returns only destinations of that kind" do
      expect(Wayfinding.of_kind(:report).map(&:name))
        .to contain_exactly(:pay_report, :margin_report, :unguarded_report)
    end

    it "excludes destinations with no kind" do
      expect(Wayfinding.of_kind(:report).map(&:name)).not_to include(:home)
    end

    it "still resolves a kinded destination by point lookup" do
      expect(Wayfinding.path_for(:pay_report)).to eq("/installer_pay_reports")
    end

    describe "#accessible_by" do
      it "keeps destinations the ability permits" do
        ability = FakeAbility.new(view_pay: Object)

        expect(Wayfinding.of_kind(:report).accessible_by(ability).map(&:name)).to eq(%i[pay_report])
      end

      it "excludes destinations with no action to authorize against" do
        ability = FakeAbility.new(view_pay: Object, view_margin: Object)

        expect(Wayfinding.of_kind(:report).accessible_by(ability).map(&:name))
          .to contain_exactly(:pay_report, :margin_report)
      end
    end
  end
end
