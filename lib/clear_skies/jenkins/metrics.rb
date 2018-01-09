require 'net/https'

module ClearSkies
  module Jenkins

    class Metrics < GreekFire::MeasureSet
      def initialize(hostname, view_name)
        @hostname = hostname
        @view_name = view_name
      end

      def items
        labels = JSON.parse(Net::HTTP.get(URI("https://#{@hostname}/view/#{@view_name}/api/json")))["jobs"].map do |job|
          GreekFire::SmartLabel.new(JSON.parse(Net::HTTP.get(URI(job["url"] + "/lastCompletedBuild/api/json"))), {job_name: job["name"], jenkins_host: @hostname})
        end


        [
          GreekFire::Gauge.new("jenkins_job_latest_job_status", labels: labels)  do |labels|
            labels.value["result"] == "SUCCESS" ? 1 : 0                 
          end,
          GreekFire::Gauge.new("jenkins_job_latest_duration", labels: labels)  do |labels|
            labels.value["duration"]                
          end
        ]
      end
    end
  end
end
