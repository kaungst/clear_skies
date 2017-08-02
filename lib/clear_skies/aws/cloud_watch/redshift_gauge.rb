module ClearSkies
  module AWS
    module CloudWatch
      class RedshiftGauge < ClearSkies::AWS::CloudWatch::Gauge
        def initialize(metric_name, dimension, statistics, description: nil, &block)
          super("AWS/Redshift", metric_name, dimension, statistics, description: description, &block)
        end

        def extra_labels(cluster_id)
          labels = {}

          cluster = Aws::Redshift::Client.new.describe_clusters({
                                                                    cluster_identifier: cluster_id
                                                                }).clusters[0]

          vpc_id = cluster.vpc_id
          labels["vpc_id"] = vpc_id if vpc_id.present?

          cluster.tags.each do |tag|
            labels[tag.key.downcase] = tag.value
          end
          labels
        rescue Aws::Redshift::Errors::ClusterNotFound
          return labels
        end

        def labels_from_metric(metric)
          labels = super(metric)

          if labels.has_key?("cluster_identifier")
            labels.merge!(Rails.cache.fetch("#{labels["cluster_identifier"]}_extra_labels_", expires_in: 1.hour, race_condition_ttl: 60.seconds) do
              extra_labels(labels["cluster_identifier"])
            end)
          end
          labels
        end
      end
    end
  end
end
