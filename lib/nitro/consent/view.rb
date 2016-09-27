module Nitro
  module Consent
    class View < Struct.new(:key, :label, :instance_conditions, :collection_conditions)
      def conditions(*args)
        collection_conditions.call(*args)
      end
    end
  end
end
