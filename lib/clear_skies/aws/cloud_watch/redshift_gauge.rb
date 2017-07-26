module ClearSkies
  module AWS
    module CloudWatch
      class RedshiftGauge < ClearSkies::AWS::CloudWatch::Gauge
        def initialize(metric_name, dimension, statistics, description: nil, &block)
          super("AWS/Redshift", metric_name, dimension, statistics, description: description, &block)
        end

        def tags(db)
          labels = {}
          db.client.list_tags_for_resource(resource_name: db.db_instance_arn).tag_list.each do |tag|
            labels[tag.key.downcase] = tag.value
          end
          labels
        end

        def labels_from_metric(metric)
          labels = super(metric)

          if labels.has_key?( "db_instance_identifier") && !(Rails.cache.fetch("#{labels["db_instance_identifier"]}_skip"))
            db = Aws::RDS::DBInstance.new(labels["db_instance_identifier"])

            vpc_id = Rails.cache.fetch("#{labels["db_instance_identifier"]}_vpc_id_") do
              db.db_subnet_group&.vpc_id
            end

            labels["vpc_id"] = vpc_id if vpc_id.present?

            labels.merge!(Rails.cache.fetch("#{labels["db_instance_identifier"]}_tags_", expires_in: 1.hour, race_condition_ttl: 60.seconds) do
              tags(db)
            end)
          end
          labels
        rescue Aws::RDS::Errors::DBInstanceNotFound
          Rails.cache.write("#{labels["db_instance_identifier"]}_skip", true, expires_in: 1.hour, race_condition_ttl: 60.seconds)
          return labels
        end
      end
    end
  end
end
