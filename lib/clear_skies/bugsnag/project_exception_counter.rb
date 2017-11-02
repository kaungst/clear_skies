require 'bugsnag/api'

module ClearSkies
  module Bugsnag
    class ProjectExceptionCounter < GreekFire::Counter
      def initialize(org_id)
        @org_id = org_id
        super("bugsnag_exceptions") { |labels| make_request_for_labels(labels) }
      end

      def make_request_for_labels(labels)
        options = {:query => 
          {"resolution" => "12h",
           "filters" =>
           {
            "event.since" => 
            [
              {
                "type" => "eq", 
                "value" => Time.now.in_time_zone("UTC").at_beginning_of_day.iso8601
              }
            ],
            "app.release_stage" =>
            [
              {
                "type" => "eq",
                "value" => labels[:release_stage]
              }
            ]
            }
          }
        }
        project = labels.value
        ::Bugsnag::Api.get("projects/#{project["id"]}/trend", options).map { |trend| trend[:events_count]}.sum
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
