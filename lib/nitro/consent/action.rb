module Nitro
  module Consent
    class Action < Struct.new(:subject, :key, :label, :options)
      def view_keys
        subject.views.keys & options.fetch(:views, [])
      end

      def views
        subject.views.values_at(*view_keys)
      end
    end
  end
end
