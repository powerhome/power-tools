# frozen_string_literal: true

require "spec_helper"

module MyModule
  class MyClass # rubocop:disable Lint/EmptyClass
  end
end

RSpec.describe Consent::Permission, type: :model do
  describe "validation" do
    it "requires a valid subject" do
      permission = Consent::Permission.new(subject: nil)

      expect(permission).to_not be_valid
      expect(permission.errors[:subject]).to match_array ["can't be blank"]
    end

    it "requires a valid action" do
      permission = Consent::Permission.new(action: nil)

      expect(permission).to_not be_valid
      expect(permission.errors[:action]).to match_array ["can't be blank"]
    end

    it "requires a valid view" do
      permission = Consent::Permission.new(view: nil)

      expect(permission).to_not be_valid
      expect(permission.errors[:view]).to match_array ["can't be blank"]
    end

    it "requires a view to provide access, not take" do
      permission = Consent::Permission.new(view: :no_access)

      expect(permission).to_not be_valid
      expect(permission.errors[:view]).to match_array ["must grant access"]
    end

    it "is valid when it has subject, action, and view" do
      permission = Consent::Permission.new(
        subject: :something,
        action: :read,
        view: :all
      )

      expect(permission).to be_valid
    end
  end

  describe ".to" do
    it "is the collection of permissions matching the given criteria" do
      _perm1 = Consent::Permission.create(role_id: 1, subject: :cars, action: :drive, view: :all)
      perm2 = Consent::Permission.create(role_id: 2, subject: :cars, action: :fix, view: :all)
      _perm3 = Consent::Permission.create(role_id: 3, subject: :motorcycle, action: :drive, view: :all)

      permissions = Consent::Permission.to(subject: :cars, action: :fix, view: :all)

      expect(permissions.pluck(:id)).to match_array [perm2.id]
    end

    it "ignores the action when not given" do
      perm1 = Consent::Permission.create(role_id: 1, subject: :cars, action: :drive, view: :all)
      perm2 = Consent::Permission.create(role_id: 2, subject: :cars, action: :drive, view: :local)
      _perm3 = Consent::Permission.create(role_id: 3, subject: :motorcycle, action: :drive, view: :all)

      permissions = Consent::Permission.to(subject: :cars)

      expect(permissions.pluck(:id)).to match_array [perm1.id, perm2.id]
    end

    it "ignores the view when not given" do
      perm1 = Consent::Permission.create(role_id: 1, subject: :cars, action: :drive, view: :all)
      perm2 = Consent::Permission.create(role_id: 2, subject: :cars, action: :drive, view: :local)
      _perm3 = Consent::Permission.create(role_id: 3, subject: :motorcycle, action: :drive, view: :all)

      permissions = Consent::Permission.to(subject: :cars, action: :drive)

      expect(permissions.pluck(:id)).to match_array [perm1.id, perm2.id]
    end

    it "filters with multiple views" do
      perm1 = Consent::Permission.create(role_id: 1, subject: :cars, action: :drive, view: :all)
      _perm2 = Consent::Permission.create(role_id: 2, subject: :cars, action: :drive, view: :local)
      perm3 = Consent::Permission.create(role_id: 3, subject: :cars, action: :drive, view: :parked)

      permissions = Consent::Permission.to(subject: :cars, action: :drive, view: %i[all parked])

      expect(permissions.pluck(:id)).to match_array [perm1.id, perm3.id]
    end
  end

  describe "#subject" do
    it "can be a class" do
      permission = Consent::Permission.new(subject: ::MyModule::MyClass)

      expect(permission.subject).to be ::MyModule::MyClass
    end

    it "can be set from a snake cased string" do
      permission = Consent::Permission.new(subject: "my_module/my_class")

      expect(permission.subject).to be ::MyModule::MyClass
    end

    it "can be serialized and reloaded" do
      permission = Consent::Permission.create(
        subject: "my_module/my_class",
        action: :read,
        view: :all
      )

      expect(permission.reload.subject).to be ::MyModule::MyClass
    end
  end

  describe "#view" do
    it 'is "1" when boolean full access' do
      permission = Consent::Permission.new(view: "1")

      expect(permission.view).to eql "1"
    end

    it 'is "1" when boolean full access' do
      permission = Consent::Permission.new(view: "true")

      expect(permission.view).to eql "1"
    end

    it "is a symbol when a view name" do
      permission = Consent::Permission.new(view: "everything")

      expect(permission.view).to be :everything
    end
  end

  describe "history" do
    it "creates a history entry when a permission is granted" do
      expect do
        Consent::Permission.create(role_id: 13, subject: :book, action: :read, view: :short)
      end.to change { Consent::History.where(role_id: 13).count }.by(1)

      created_history = Consent::History.where(role_id: 13).last

      expect(created_history.command).to eql "grant"
      expect(created_history.subject).to be :book
      expect(created_history.action).to eql "read"
      expect(created_history.view).to eql "short"
    end

    it "creates a history entry when a permission is changed" do
      permission = Consent::Permission.create(role_id: 13, subject: :book, action: :read, view: :short)
      expect do
        permission.update(view: :long)
      end.to change { Consent::History.where(role_id: 13).count }.by(1)

      created_history = Consent::History.where(role_id: 13).last

      expect(created_history.command).to eql "grant"
      expect(created_history.subject).to be :book
      expect(created_history.action).to eql "read"
      expect(created_history.view).to eql "long"
    end

    it "creates a history entry when a permission is revoked" do
      permission = Consent::Permission.create(role_id: 13, subject: :book, action: :read, view: :short)
      expect do
        permission.destroy
      end.to change { Consent::History.where(role_id: 13).count }.by(1)

      created_history = Consent::History.where(role_id: 13).last

      expect(created_history.command).to eql "revoke"
      expect(created_history.subject).to be :book
      expect(created_history.action).to eql "read"
      expect(created_history.view).to eql "short"
    end
  end
end
