require 'bugsnag/api'

module ClearSkies
  module Bugsnag
    class ProjectErrorCounter < GreekFire::Counter
      def initialize(org_id)
        @org_id = org_id
        super("bugsnag_open_errors") { |label| make_request_for_label(label) }
      end

      def make_request_for_label(label)
        filters = {
          "error.status" => [{ "type" => "eq", "value" => "open" }],
          "app.release_stage" => [{ "type" => "eq", "value" => label[:release_stage] }]
        }
        project = label.value
        ::Bugsnag::Api.errors(project["id"], nil, filters: filters).size
      end

      def labels
        labels = []
        ::Bugsnag::Api.projects(@org_id).each do |project|
          project[:release_stages].each do |release_stage|
            labels << GreekFire::SmartLabel.new(project, project_name: project["name"], release_stage: release_stage)
          end
        end
        labels
      end
    end
  end
end