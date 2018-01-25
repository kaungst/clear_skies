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

          GreekFire::SmartLabel.new(delivered_story_count, { project_id: project_id })
        end

        [GreekFire::Gauge.new("delivered_story_count", labels: labels) do |label|
          label.value
        end]
      end

      private
      attr_accessor :project_ids, :api_token
    end
  end
end
