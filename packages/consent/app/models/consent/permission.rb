# frozen_string_literal: true

module Consent
  class Permission < ::Consent::ApplicationRecord
    serialize :subject, ::Consent::SubjectCoder

    validates :subject, presence: true
    validates :action, presence: true
    validates :view, presence: true,
                     exclusion: {
                       in: [::Consent::NO_ACCESS],
                       message: "must grant access",
                     }
    after_save { ::Consent::History.record(:grant, self) }
    after_destroy { ::Consent::History.record(:revoke, self) }

    scope :to, ->(subject:, action: nil, view: nil) do
      where({ subject: subject, action: action, view: view }.compact)
    end

    # It is true when it is a replacement for another permission
    # @private
    #
    def replaces?(permission)
      subject == permission.subject && action == permission.action
    end

    # Symbol key of an action
    #
    def action
      super&.to_sym
    end

    # Symbol key of a view or "1" for full access
    #
    def view
      return "1" if Consent::FULL_ACCESS.include?(super)

      super&.to_sym
    end

    # Transforms a hash of permissions and views to grant into a collection
    # of Consent::Permission
    #
    # I.e.:
    #   Permission.from_hash User => { write: :territory }
    #   => [#<Consent::Permission view: :territory, action: :write, subject: User>]
    #
    #   Permission.from_hash User => { write: :territory, read: :all }
    #   => [#<Consent::Permission view: :territory, action: :write, subject: User>,]
    #       #<Consent::Permission view: :all, action: :read, subject: User>]
    #
    # It also eliminates any invalid permission from the resulting set
    #
    # I.e.:
    #   Permission.from_hash User => { write: :territory, read: :no_access }, Department: { write: :all }
    #   => [#<Consent::Permission view: :territory, action: :write, subject: User>,]
    #       #<Consent::Permission view: :all, action: :write, subject: Department>]
    #
    # @param permissions [Hash] a set of permissions in the hash format
    # @return [Array<Consent::Permission>]
    #
    def self.from_hash(permissions)
      permissions.flat_map do |subject, actions|
        actions.flat_map do |action, view|
          new(subject: subject, action: action, view: view)
        end
      end.select(&:valid?)
    end
  end
end
