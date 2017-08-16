module ClearSkies
  module AWS

    module CloudWatch
      class ELBGauge < ClearSkies::AWS::CloudWatch::Gauge
        def self.elb_client
          @elb_client ||= Aws::ElasticLoadBalancing::Client.new
        end
        def initialize(metric_name, dimension, statistics, description: nil, aws_parameters:nil, &block)
          super("AWS/ELB", metric_name, dimension, statistics, description: description, aws_parameters: aws_parameters, &block)
        end

        def tags(load_balancer_name)
          labels = {}
          ELBGauge.elb_client.
              describe_tags({load_balancer_names: [load_balancer_name]}).
              tag_descriptions.
              select {|doc| doc.load_balancer_name == load_balancer_name}.each do |tag_description|
            tag_description.tags.each do |tag|
              labels[tag.key.downcase] = tag.value
            end
          end
          labels
        end

        def labels_from_metric(metric)
          labels = super(metric)

          if labels.has_key?( "load_balancer_name") && !(Rails.cache.fetch("#{labels["load_balancer_name"]}_skip"))

            labels["vpc_id"] = Rails.cache.fetch("#{labels["load_balancer_name"]}_vpc_id_") do
              ELBGauge.elb_client.describe_load_balancers(load_balancer_names: [labels["load_balancer_name"]]).load_balancer_descriptions.first.vpc_id
            end

            labels.merge!(Rails.cache.fetch("#{labels["load_balancer_name"]}_tags_", expires_in: 1.hour, race_condition_ttl: 60.seconds) do
              tags(labels["load_balancer_name"])
            end)
          end
          labels
        rescue Aws::ElasticLoadBalancing::Errors::LoadBalancerNotFound
          Rails.cache.write("#{labels["load_balancer_name"]}_skip", true, expires_in: 1.hour, race_condition_ttl: 60.seconds)
          return labels
        end
      end
    end
  end
end
