module ClearSkies
  module AWS
    class ReservationUtilization < GreekFire::MeasureSet
      def items
        client = Aws::EC2::Client.new()
        reservations = client.describe_reserved_instances.reserved_instances
        active_reservations = reservations.map { |x| ReservationMatcher.new(x) if x.state == "active" }.compact
        current_reservations = reservations.map { |x| ReservationMatcher.new(x) if x.start < Time.now && x.start + x.duration > Time.now && x.fixed_price > 0}.compact

        instance_counts = Hash.new { 0 }

        instance_spawns = client.describe_instances(filters: [{name: "instance-state-name", values: ["running"]}])

        instance_spawns.reservations.each do |spawn|
          spawn.instances.each do |instance|
            active_reservations.find { |reservation| reservation.match(instance) }

            instance_counts[{instance_type: instance.instance_type, availability_zone: instance.placement.availability_zone, tenancy: instance.placement.tenancy}] += 1
          end
        end

        [
            ReservationExpirationGauge.new(active_reservations),
            ReservationPurchasedGauge.new(active_reservations),
            ReservationDailyCostGauge.new(current_reservations),
            ReservationUsageGauge.new(active_reservations),
            InstancesGauge.new(instance_counts)
        ]
      end
    end

    class ReservationMatcher
      attr_reader :reservation, :match_count, :instance_count

      def initialize(reservation)
        @reservation = reservation
        @instance_count = reservation.instance_count

        @match_count = 0
      end

      def expires_in
        @reservation.end - Time.now
      end

      def daily_cost
        (reservation.fixed_price * instance_count) / (reservation.duration / 1.day)
      end

      def match(instance)
        return false if match_count >= instance_count
        return false unless @reservation.instance_type == instance.instance_type
        return false unless @reservation.scope == "Region" || @reservation.availability_zone == instance.placement.availability_zone
        return false unless @reservation.instance_tenancy == instance.placement.tenancy

        @match_count += 1
        return true
      end

      def labels
        {
            reserved_instances_id: @reservation.reserved_instances_id,
            instance_type: @reservation.instance_type,
            availability_zone: @reservation.availability_zone || "Region",
            tenancy: @reservation.instance_tenancy,
        }
      end
    end

    class InstancesGauge < GreekFire::Gauge
      def initialize(instance_counts)
        super("aws_ec2_instances", description: "Number of instances running by type") do |labels|
          labels.delete(:count)
        end

        @instance_counts = instance_counts
      end

      def labels
        @instance_counts.map do |labels, count|
          labels.merge(count: count)
        end
      end
    end

    class ReservationPurchasedGauge < GreekFire::Gauge
      def initialize(reservations)
        super("aws_ec2_reservation_purchases", description: "Number of instance reservations purchased") do |labels|
          labels.delete(:reservation).instance_count
        end

        @reservations = reservations
      end

      def labels
        @reservations.map do |reservation|
          reservation.labels.merge(reservation: reservation)
        end
      end
    end

    class ReservationDailyCostGauge < GreekFire::Gauge
      def initialize(reservations)
        super("aws_ec2_reservation_amortized_daily_price", description: "Amortized daily cost of reservation") do |labels|
          labels.delete(:reservation).daily_cost
        end

        @reservations = reservations
      end

      def labels
        @reservations.map do |reservation|
          reservation.labels.merge(reservation: reservation)
        end
      end
    end

    class ReservationUsageGauge < GreekFire::Gauge
      def initialize(reservations)
        super("aws_ec2_reservation_usage", description: "Number of instance reservations in use") do |labels|
          labels.delete(:reservation).match_count
        end

        @reservations = reservations
      end

      def labels
        @reservations.map do |reservation|
          reservation.labels.merge(reservation: reservation)
        end
      end
    end

    class ReservationExpirationGauge < GreekFire::Gauge
      def initialize(reservations)
        super("aws_ec2_reservation_expire_in", description: "seconds until instance reservation expires") do |labels|
          labels.delete(:reservation).expires_in
        end

        @reservations = reservations
      end

      def labels
        @reservations.map do |reservation|
          reservation.labels.merge(reservation: reservation)
        end
      end
    end

  end
end
