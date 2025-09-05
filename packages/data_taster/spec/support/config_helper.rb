# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do
    # several class instance variables are set and memoized, so this lets us reset them between tests
    DataTaster.instance_variables.each do |variable|
      DataTaster.remove_instance_variable(variable) if DataTaster.instance_variable_defined?(variable)
    end
  end
end
