require 'uri'
require 'net/https'
require 'json'

module ClearSkies
  module Gemnasium
    class GemnasiumApi
      ALL_GEMNASIUM_PROJECTS_URI = "https://api.gemnasium.com/v1/projects"
      GEMNASIUM_BASE_URI = "https://api.gemnasium.com/v1/projects/%s/alerts"

      def initialize(api_key:)
        self.api_key = api_key
      end

      def all_projects
        body = make_request(ALL_GEMNASIUM_PROJECTS_URI)
        projects = body.fetch("owned", [])

        projects.each_with_object({}) do |project, result|
          alerts = opened_alerts(app_name: project["slug"])
          opened_alerts = alerts.count { |alert| alert["status"] == "open" }
          result[project["name"]] = opened_alerts
        end
      end

      private
      attr_accessor :api_key

      def opened_alerts(app_name:)
        make_request(GEMNASIUM_BASE_URI % [app_name])
      end

      def make_request(url)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth("X", api_key)
        http.use_ssl = true

        response = http.request(request)
        JSON.parse(response.body)
      end
    end

    class Alerts < ::GreekFire::MeasureSet
      def initialize(api_key:)
        self.api = GemnasiumApi.new(api_key: api_key)
      end

      def items
        all_projects = api.all_projects
        labels = all_projects.map do |project_name, number_of_alerts|
          GreekFire::SmartLabel.new(number_of_alerts, {project_name: project_name})
        end

        [GreekFire::Gauge.new("gemnasium_opened_alerts", labels: labels) do |labels|
          labels.value
        end]
      end

      private
      attr_accessor :api
    end
  end
end
