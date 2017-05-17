module ClearSkies
  class ElasticBeanstalkGauge < ClearSkies::Gauge
    def self.client
      @client ||= Aws::ElasticBeanstalk::Client.new
    end
    def initialize(metric_name, dimension, statistics, description: nil, &block)
      super("AWS/ElasticBeanstalk", metric_name, dimension, statistics, description: description, &block)
    end

    def application_name(environment_name)
      ElasticBeanstalkGauge.client.describe_environments({environment_names: [environment_name] }).environments.first.application_name
    end

    def vpc_id(application_name, environment_name)
      config = ElasticBeanstalkGauge.client.describe_configuration_settings({ application_name: application_name, environment_name: environment_name }).
          configuration_settings.find { |config| config.application_name == application_name && config.environment_name == environment_name}
      option =  config.option_settings.find { |option| option.namespace == "aws:ec2:vpc" && option.option_name == "VPCId"}
      option.value if option
    end


    def labels_from_metric(metric)
      labels = super(metric)

      if labels.has_key?( "environment_name") && !(Rails.cache.fetch("#{labels["environment_name"]}_skip"))

        labels["application_name"] =  Rails.cache.fetch("#{labels["environment_name"]}_application_name", expires_in: 1.hour) do
          application_name(labels["environment_name"])
        end

        labels["vpc_id"] = Rails.cache.fetch("#{labels["environment_name"]}_vpc_id_") do
          vpc_id(labels["application_name"], labels["environment_name"])
        end
      end
      labels
    rescue Aws::RDS::Errors::DBInstanceNotFound
      Rails.cache.write("#{labels["environment_name"]}_skip", true, expires_in: 1.hour, race_condition_ttl: 60.seconds)
      return labels
    end
  end
end
