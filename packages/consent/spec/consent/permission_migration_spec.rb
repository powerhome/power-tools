# frozen_string_literal: true

require "spec_helper"

require "consent/permission_migration"

describe Consent::PermissionMigration do
  include Consent::PermissionMigration

  describe ".copy_permissions" do
    it "creates a new permission based on the given permission" do
      base_permission = ::Consent::Permission.create(role_id: 1, subject: :candidate, action: :access, view: :territory)
      expect(Consent::Permission.count).to eql 1

      copy_permissions(
        from: { subject: :candidate, action: :access },
        override: { action: :full_access }
      )

      new_permission = Consent::Permission.where.not(id: base_permission.id).first
      expect(new_permission.subject).to eql :candidate
      expect(new_permission.action).to eql :full_access
      expect(new_permission.view).to eql :territory
    end
  end

  describe ".update_permissions" do
    matcher :be_renamed_to do |expected|
      match do |actual|
        actual_attrs = actual.reload.slice(expected.keys).to_a
        expected_attrs = expected.stringify_keys.to_a
        expect(actual_attrs).to eql expected_attrs
      end
      failure_message do |actual|
        "expected permission #{actual.inspect} to grant #{expected}"
      end
    end

    it "renames a subject affecting all grantted permissions keeping everything else" do
      sale_perform_territory = ::Consent::Permission.create(role_id: 1, subject: :sale, action: :perform,
                                                            view: :territory)
      sale_perform_all = ::Consent::Permission.create(role_id: 2, subject: :sale, action: :perform, view: :all)
      sale_read_territory = ::Consent::Permission.create(role_id: 4, subject: :sale, action: :read, view: :territory)
      user_read_territory = ::Consent::Permission.create(role_id: 4, subject: :user, action: :read, view: :territory)

      update_permissions(
        from: { subject: :sale },
        to: { subject: :project }
      )

      expect(sale_perform_territory).to be_renamed_to(subject: :project, action: :perform, view: :territory)
      expect(sale_perform_all).to be_renamed_to(subject: :project, action: :perform, view: :all)
      expect(sale_read_territory).to be_renamed_to(subject: :project, action: :read, view: :territory)
      expect(user_read_territory).to be_renamed_to(subject: :user, action: :read, view: :territory)
    end

    it "can move an action from a subject to another keeping the view" do
      sale_perform_territory = ::Consent::Permission.create(role_id: 1, subject: :sale, action: :perform,
                                                            view: :territory)
      sale_perform_all = ::Consent::Permission.create(role_id: 2, subject: :sale, action: :perform, view: :all)
      sale_read_territory = ::Consent::Permission.create(role_id: 4, subject: :sale, action: :read, view: :territory)
      user_read_territory = ::Consent::Permission.create(role_id: 4, subject: :user, action: :read, view: :territory)

      update_permissions(
        from: { subject: :sale, action: :perform },
        to: { subject: :project }
      )

      expect(sale_perform_territory).to be_renamed_to(subject: :project, action: :perform, view: :territory)
      expect(sale_perform_all).to be_renamed_to(subject: :project, action: :perform, view: :all)
      expect(sale_read_territory).to be_renamed_to(subject: :sale, action: :read, view: :territory)
      expect(user_read_territory).to be_renamed_to(subject: :user, action: :read, view: :territory)
    end

    it "can rename an action within a subject keeping the view" do
      sale_perform_territory = ::Consent::Permission.create(role_id: 1, subject: :sale, action: :perform,
                                                            view: :territory)
      sale_perform_all = ::Consent::Permission.create(role_id: 2, subject: :sale, action: :perform, view: :all)
      sale_read_territory = ::Consent::Permission.create(role_id: 4, subject: :sale, action: :read, view: :territory)
      user_read_territory = ::Consent::Permission.create(role_id: 4, subject: :user, action: :read, view: :territory)

      update_permissions(
        from: { subject: :sale, action: :read },
        to: { action: :inspect }
      )

      expect(sale_perform_territory).to be_renamed_to(subject: :sale, action: :perform, view: :territory)
      expect(sale_perform_all).to be_renamed_to(subject: :sale, action: :perform, view: :all)
      expect(sale_read_territory).to be_renamed_to(subject: :sale, action: :inspect, view: :territory)
      expect(user_read_territory).to be_renamed_to(subject: :user, action: :read, view: :territory)
    end

    it "can rename a view within a subject and action context" do
      sale_perform_territory = ::Consent::Permission.create(role_id: 1, subject: :sale, action: :perform,
                                                            view: :territory)
      sale_perform_all = ::Consent::Permission.create(role_id: 2, subject: :sale, action: :perform, view: :all)
      sale_read_territory = ::Consent::Permission.create(role_id: 4, subject: :sale, action: :read, view: :territory)
      user_read_territory = ::Consent::Permission.create(role_id: 4, subject: :user, action: :read, view: :territory)

      update_permissions(
        from: { subject: :sale, action: :read, view: :territory },
        to: { view: :department_territory }
      )

      expect(sale_perform_territory).to be_renamed_to(subject: :sale, action: :perform, view: :territory)
      expect(sale_perform_all).to be_renamed_to(subject: :sale, action: :perform, view: :all)
      expect(sale_read_territory).to be_renamed_to(subject: :sale, action: :read, view: :department_territory)
      expect(user_read_territory).to be_renamed_to(subject: :user, action: :read, view: :territory)
    end
  end
end
