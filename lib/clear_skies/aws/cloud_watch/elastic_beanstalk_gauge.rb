module ClearSkies
  module AWS
    module CloudWatch
      class ElasticBeanstalkGauge < ClearSkies::AWS::CloudWatch::Gauge
        def self.beanstalk_client
          @beanstalk_client ||= ::Aws::ElasticBeanstalk::Client.new
        end
        def initialize(metric_name, dimension, statistics, description: nil, aws_parameters:nil, &block)
          super("AWS/ElasticBeanstalk", metric_name, dimension, statistics, description: description, aws_parameters: aws_parameters, &block)
        end

        def application_name(environment_name)
          ElasticBeanstalkGauge.beanstalk_client.describe_environments({environment_names: [environment_name] }).environments.first&.application_name
        end

        def vpc_id(application_name, environment_name)
          config = ElasticBeanstalkGauge.beanstalk_client.describe_configuration_settings({ application_name: application_name, environment_name: environment_name }).
              configuration_settings.find { |config| config.application_name == application_name && config.environment_name == environment_name}
          option =  config.option_settings.find { |option| option.namespace == "aws:ec2:vpc" && option.option_name == "VPCId"}
          option.value if option
        end


        def labels_from_metric(metric)
          labels = super(metric)

          if labels.has_key?( "environment_name") && !(Rails.cache.fetch("#{labels["environment_name"]}_skip"))
            application_name = Rails.cache.fetch("#{labels["environment_name"]}_application_name", expires_in: 1.hour) do
              application_name(labels["environment_name"])
            end
            if application_name
              labels["application_name"] =  application_name

              labels["vpc_id"] = Rails.cache.fetch("#{labels["environment_name"]}_vpc_id_") do
                vpc_id(labels["application_name"], labels["environment_name"])
              end
            end
          else
            Rails.cache.write("#{labels["environment_name"]}_skip", true, expires_in: 1.hour, race_condition_ttl: 60.seconds)
          end

          return labels
        end
      end
    end
  end
end
