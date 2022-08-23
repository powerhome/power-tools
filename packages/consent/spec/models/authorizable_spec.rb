# frozen_string_literal: true

require "spec_helper"

RSpec.describe ::Consent::Authorizable, type: :model do
  describe "#grant" do
    let(:role) { ExampleRole.new }

    it "grants the given permission to the role" do
      role.grant subject: :report, action: :projects, view: :all

      expect(role.permissions.size).to eql 1
      expect(role.permissions.first.subject).to eql :report
      expect(role.permissions.first.action).to eql :projects
      expect(role.permissions.first.view).to eql :all
    end

    it "replaces the currently granted view on the given subject/action" do
      role.grant subject: :report, action: :projects, view: :all
      role.grant subject: :report, action: :projects, view: :territory

      role.save!

      expect(role.permissions.size).to eql 1
      expect(role.permissions.first.subject).to eql :report
      expect(role.permissions.first.action).to eql :projects
      expect(role.permissions.first.view).to eql :territory
    end

    it "does not allow granting an invalid permission" do
      role.grant subject: :report, action: :projects, view: :no_access

      expect(role.permissions).to be_empty
    end
  end

  describe "#grant_all" do
    let(:role) { ExampleRole.new }

    it "adds all given permissions to the set" do
      role.grant_all(reports: { candidates: :all })
      role.grant_all(reports: { users: :territory })

      expect(role.permissions.size).to eql 2
      expect(role.permissions.first.subject).to eql :reports
      expect(role.permissions.first.action).to eql :candidates
      expect(role.permissions.first.view).to eql :all
      expect(role.permissions.last.subject).to eql :reports
      expect(role.permissions.last.action).to eql :users
      expect(role.permissions.last.view).to eql :territory
    end

    it "replaces a given permission when it matches" do
      role.grant_all(reports: { candidates: :all, users: :territory })
      role.grant_all(reports: { users: :all })

      role.save!

      expect(role.permissions.size).to eql 2
      expect(role.permissions.first.subject).to eql :reports
      expect(role.permissions.first.action).to eql :candidates
      expect(role.permissions.first.view).to eql :all
      expect(role.permissions.last.subject).to eql :reports
      expect(role.permissions.last.action).to eql :users
      expect(role.permissions.last.view).to eql :all
    end

    it "replaces all existing permissions when required" do
      role.grant_all(reports: { candidates: :all, users: :territory })
      role.save!

      role.grant_all({ reports: { sales: :department } }, replace: true)

      role.save!

      expect(role.permissions.size).to eql 1
      expect(role.permissions.first.subject).to eql :reports
      expect(role.permissions.first.action).to eql :sales
      expect(role.permissions.first.view).to eql :department
    end

    it "ignores no access grants" do
      role.grant_all(reports: { candidates: :no_access, users: :no_access, sales: :no_access, projects: :all })

      expect(role.permissions.size).to eql 1
      expect(role.permissions.first.subject).to eql :reports
      expect(role.permissions.first.action).to eql :projects
      expect(role.permissions.first.view).to eql :all
    end

    describe "grant_all!" do
      it "saves the changes atomically" do
        role.grant_all!(reports: { users: :no_access, projects: :all })
        role.grant_all!(reports: { users: :all, projects: :no_access }) do
          raise
        end
      rescue
        role.permissions.reload

        expect(role.permissions.size).to eql 1
        expect(role.permissions.first.subject).to eql :reports
        expect(role.permissions.first.action).to eql :projects
        expect(role.permissions.first.view).to eql :all
      end
    end
  end
end
