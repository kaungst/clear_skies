require 'net/https'
require 'cgi'

module ClearSkies
  module Jenkins

    class Metrics < GreekFire::MeasureSet
      def initialize(hostname, view_name)
        @hostname = hostname
        @view_name = view_name
      end

      def items
        labels = JSON.parse(Net::HTTP.get(URI("https://#{@hostname}/view/#{@view_name}/api/json")))["jobs"].map do |job|
          name = begin
                   if job["name"] == "master" && job["_class"] == "org.jenkinsci.plugins.workflow.job.WorkflowJob"
                     parts = job["url"].split('/')
                     project_name = CGI.unescape parts[-3]
                     branch_name = parts[-1]
                     "#{project_name}/#{branch_name}"
                   else
                     job["name"]
                   end
                 rescue
                   job["name"]
                 end
          GreekFire::SmartLabel.new(JSON.parse(Net::HTTP.get(URI(job["url"] + "/lastCompletedBuild/api/json"))), {job_name: name, jenkins_host: @hostname})
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
