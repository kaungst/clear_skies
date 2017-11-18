module ClearSkies
  module AWS
    class RdsReservationUtilization < GreekFire::MeasureSet
      def items
        client = Aws::RDS::Client.new
        reservations = client.describe_reserved_db_instances.reserved_db_instances
        instances = client.describe_db_instances.db_instances

        reservation_counts = Hash.new { 0 }
        reservations.each do |res|
          reservation_counts[{
            db_instance_class: res.db_instance_class,
            engine: formatted_engine_name(res.product_description),
            region: res.reserved_db_instance_arn.split(':')[3]
          }] += res.db_instance_count
        end

        instance_counts = Hash.new { 0 }
        instances.each do |inst|
          instance_counts[{
            db_instance_class: inst.db_instance_class,
            engine: inst.engine,
            region: inst.db_instance_arn.split(':')[3]
          }] += 1
        end


        [
            RDSUtilizationGauge.new(reservation_counts, :reservations),
            RDSUtilizationGauge.new(instance_counts, :instances)
        ]
      end

      private

      def formatted_engine_name(raw_name)
        # necessary because API returns "postgresql" in reservation descriptions and "postgres" in instance descriptions
        raw_name == "postgresql" ? "postgres" : raw_name
      end
    end

    class RDSUtilizationGauge < GreekFire::Gauge
      def initialize(counts, type)
        super("aws_rds_#{type}", description: "Number of RDS #{type} by instance class, engine, and region") do |labels|
          labels.delete(:count)
        end

        @counts = counts
      end

      def labels
        @counts.map do |labels, count|
          labels.merge(count: count)
        end
      end
    end
  end
end
