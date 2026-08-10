# frozen_string_literal: true

# Minimal stand-in for a Rails engine. Wayfinding only ever reaches for
# engine.routes.url_helpers, so booting Rails to exercise it would be waste.
class FakeEngine
  class UrlHelpers
    def home_path(home, **params)
      query = params.map { |key, value| "#{key}=#{value}" }.join("&")

      query.empty? ? "/homes/#{home}" : "/homes/#{home}?#{query}"
    end

    def home_url(home, **params) = "https://nitro.test#{home_path(home, **params)}"

    def lead_source_path(lead_source) = "/lead_sources/#{lead_source}"

    def installer_pay_reports_path = "/installer_pay_reports"

    def legacy_home = "/legacy_home"
  end

  class Routes
    def url_helpers = @url_helpers ||= UrlHelpers.new
  end

  def self.routes = @routes ||= Routes.new
end

# Stands in for a CanCan ability.
class FakeAbility
  def initialize(permitted = {})
    @permitted = permitted
  end

  def can?(action, subject) = @permitted[action] == subject
end
