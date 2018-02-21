require 'tracker_api'

module ClearSkies
  module PivotalTracker
    class Metrics < GreekFire::MeasureSet
      def initialize(project_ids:, api_token:)
        self.project_ids = project_ids
        self.api_token = api_token
      end

      def items
        client = TrackerApi::Client.new({ token: api_token })

        labels = project_ids.map do |project_id|
          project = client.project(project_id)

          delivered_story_count = project.stories(with_state: :delivered).count
          in_flight_story_count = project.stories(with_state: :started).count

          GreekFire::SmartLabel.new(
            {
              "delivered_story_count" => delivered_story_count,
              "in_flight_story_count" => in_flight_story_count
            },
            { project_id: project_id }
          )
        end

        %w(
          delivered_story_count
          in_flight_story_count
        ).map { |name| self.class.generate_gauge(name, labels) }
      end

      private
      attr_accessor :project_ids, :api_token

      def self.generate_gauge(name, labels)
        GreekFire::Gauge.new(name, labels: labels) { |label| label.value[name] }
      end
    end
  end
end
