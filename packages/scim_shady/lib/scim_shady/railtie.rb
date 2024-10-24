# frozen_string_literal: true

require "scim_shady"

module ScimShady
  class Railtie < Rails::Railtie
    initializer "scim_shady.client" do |app|
      config = app.config_for(:scim)
      ScimShady.client = ScimShady::Client.new(**config)
    end
  end
end
