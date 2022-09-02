# frozen_string_literal: true

module Consent
  # Permission migration helper module
  module PermissionMigration
    # Copy permissions from one existing permission into a new permission selecting with
    # attrs would be overrided.
    #
    # I.e.:
    #
    #   copy_permissions(
    #     from: { subject: :sale, action: :view },
    #     override: { subject: :project }
    #   )
    #
    # @param from [Hash] a hash with `:subject` and `:action` to select which permissions to copy
    # @param override [Hash] hash to specify which fields/values to override
    #
    def copy_permissions(from:, override:)
      raise ArgumentError, "Subject and Action are always required" if from[:subject].blank? || from[:action].blank?

      ::Consent::Permission.to(**from).each do |permission|
        ::Consent::Permission.create!(
          permission.slice(:subject, :action, :view, :role_id).merge(override)
        )
      end
    end

    # Grant a permission to a collection of roles.
    #
    # I.e.:
    #
    #   grant_permission(
    #     subject: :view_installer_pay_report,
    #     action: ProjectTask,
    #     role_ids: [2, 7, 140]
    #   )
    #
    # @param subject [symbol] the permission's subject
    # @param action [Class, symbol] the permission's action
    # @param role_ids [Array<Integer>] the collection of role_ids to grant the permission to
    # @param view [String, nil] the view level, or access level, that the permission will be
    #   assigned at. If not specified, this will default to true ("1")
    #
    def grant_permission(subject:, action:, role_ids:, view: "1")
      role_ids.each do |role_id|
        ::Consent::Permission.create!(subject: subject,
                                      action: action,
                                      role_id: role_id,
                                      view: view)
      end
    end

    # Removes a permission from a collection of roles.
    #
    # I.e.:
    #
    #   remove_permission(
    #     subject: :view,
    #     action: User,
    #     role_ids: [78, 12]
    #   )
    #
    # @param subject [symbol] the permission's subject
    # @param action [Class, symbol] the permission's action
    # @param role_ids [Array<Integer>] the collection of role_ids to grant the permission to
    #
    def remove_permission(subject:, action:, role_ids:)
      role_ids.each do |role_id|
        permission = ::Consent::Permission.find_by(subject: subject,
                                                   action: action,
                                                   role_id: role_id)
        permission.destroy!
      end
    end

    # Batch updates permission data
    #
    # * CAUTION *
    #    Updating a permission in a migration means that for some time the old permission
    #  will be broken in production. So, you might lock out people between the permission
    #  running and your code getting deployed/restarted in the webservers.
    #
    #  Example:
    #  - Page A is only displayed to users that `can? :view, Candidate`
    #  - If you're willing to rename the `view` action to be `view_candidates`
    #  - Then you could go with a permission like this
    #     update_permissions(
    #      from: { subject: :candidate, action: :view },
    #      to: { action: :view_candidates }
    #     )
    #  - And you'll have to change the permission check to be `can? :view_candidates, Candidate`
    #  - When you merge your PR, then the migration will run first, and later on your code will
    #    reach production.
    #  - Between that time, the page that uses that permission will be unreachable since
    #  `can? :view, Candidate` doesn't exists anymore in the DB.
    #
    # I.e.:
    #
    # Renames a subject affecting all grantted permissions keeping everything else
    #
    #   update_permissions(
    #     from: { subject: :sale },
    #     to: { subject: :project }
    #   )
    #
    # Moves an action from a subject to another keeping the view
    #
    #   update_permissions(
    #     from: { subject: :sale, action: :perform },
    #     to: { subject: :project }
    #   )
    #
    # Rename an action within a subject keeping the view
    #
    #   update_permissions(
    #     from: { subject: :sale, action: :read },
    #     to: { action: :inspect }
    #   )
    #
    # Rename a view within a subject and action context
    #
    #   update_permissions(
    #     from: { subject: :sale, action: :read, view: :territory },
    #     to: { view: :department_territory }
    #   )
    #
    # @param from [Hash] a hash with `:subject`, `:action`, and `:view` to match the affected permissions
    # @param to [Hash] a hash with `:subject`, `:action`, and/or `:view` with the desired change
    #
    def update_permissions(from:, to:)
      raise ArgumentError, "Subject is always required" if from[:subject].blank?

      ::Consent::Permission.to(**from).find_each do |permission|
        permission.update(to)
      end
    end
  end
end
