# frozen_string_literal: true

module Consent
  module Authorizable
    extend ::ActiveSupport::Concern

    included do
      has_many :permissions, class_name: "Consent::Permission",
                             foreign_key: :role_id, inverse_of: false,
                             dependent: :delete_all, autosave: true
    end

    # Grants all permissions in o permissions hash formatted as:
    #
    # `{ <subject> => { <action> => <view> } }`
    #
    # @example role.grant_all({ "user" => { "read" => "all" }})
    # @example role.grant_all({ User => { read: :all }})
    #
    # When `replace: true`, it mark all existing permisions for destruction
    #
    # @example
    #    role.grant_all(User => { read: :territory })
    #    role.grant_all({ User => { write: :territory }, replace: true)
    #    role.permissions
    #    => [#<Consent::Permission subject: User(...), action: :write, view: :territory>]
    #
    # `grant_all` will only keep valid permissions, this excludes any permisison that grants nothing (:no_access)
    #
    # @param permissions [Hash] a hash formatted as documented above
    # @param replace [Boolean] whether we should replace all existing granted permisions
    #
    def grant_all(permissions, replace: false)
      changed = self.permissions
                    .from_hash(permissions)
                    .map { |permission| grant_permission(permission) }
      (self.permissions - changed).each(&:mark_for_destruction) if replace
    end

    # Destructive form of {Authorizable#grant_all}. This methods grants all the given permissions and
    # persists it to the database atomically
    #
    # @see #grant_all
    # @yield after saving before commiting within the transaction
    #
    def grant_all!(*args, **kwargs)
      transaction do
        grant_all(*args, **kwargs)
        tap(&:save!)
        touch
        yield if block_given?
      end
    end

    # Grants a permission to a role, replacing any existing permission for the same subject/action pair:
    #
    # @example
    #    role.grant(subject: "user", action: "read", view: "all")
    #    role.grant(subject: "user", action: "read", view: "territory")
    #    role.permissions
    #    => [#<Consent::Permission subject: User(...), action: :read, view: :territory>]
    #
    # `grant` only grants valid permissions:
    #
    # @example
    #    role.grant(subject: "user", action: "read", view: "no_access")
    #    role.permissions
    #    => []
    #
    # `grant` also does not persist the given permissions, so the caller must #save! the role
    #
    # @param subject [Symbol|String|Class] any valid subject
    # @param action [String|Symbol] a valid action
    # @param view [String|Symbol] a valid view
    #
    def grant(subject:, action:, view:)
      grant_permission ::Consent::Permission.new(subject: subject, action: action, view: view)
    end

  private

    def grant_permission(new_perm)
      existing_perm = permissions.find { |p| p.subject.eql?(new_perm.subject) && p.action.eql?(new_perm.action) }
      if existing_perm
        existing_perm.view = new_perm.view
        existing_perm.mark_for_destruction unless existing_perm.valid?
        existing_perm
      elsif new_perm.valid?
        association(:permissions).add_to_target(new_perm)
        new_perm
      end
    end
  end
end
