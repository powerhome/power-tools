# frozen_string_literal: true

module DataTracker
  class Railtie < Rails::Railtie
    railtie_name :data_tracker

    initializer "data_tracker.initialize_model_helper" do
      ActiveSupport.on_load(:active_record) do
        extend ::DataTracker::ModelHelper
      end
    end
  end
end
