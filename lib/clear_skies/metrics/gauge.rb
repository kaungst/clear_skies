
module ClearSkies
  class Gauge < GreekFire::Gauge
    include ActiveModel::Conversion

    def self.register(*args, &block)
      GreekFire::Metric.register(self.new(*args, &block))
    end

    def to_partial_path
      GreekFire::Gauge._to_partial_path
    end

    def initialize(namespace, metric_name, dimensions, statistics, description:nil, &block)
      super("#{namespace.underscore.gsub("/", "_")}_#{metric_name.underscore}", description: description)
      @namespace = namespace
      @metric_name = metric_name
      @dimensions = dimensions
      @statistics = statistics.select { |stat| ["SampleCount", "Average", "Sum", "Minimum", "Maximum"].include?(stat.to_s) }
      @extended_statistics = statistics - @statistics

      @block = block
    end

    def self.cloudwatch_client
      @client ||= Aws::CloudWatch::Client.new
    end

    def aws_metrics
       Aws::CloudWatch::Resource.new(client: Gauge.cloudwatch_client).metrics(
          namespace: @namespace,
          metric_name: @metric_name,
          dimensions: @dimensions.map {|dimension| {name: dimension} }
      ).select { |metrics| metrics.dimensions.count == @dimensions.count }
    end

    def labels_from_metric(metric)
      metric.dimensions.inject({}) do |labels, dimension|
        labels[dimension.name.underscore] = dimension.value
        labels
      end
    end

    def metrics
      aws_metrics.map do |metric|
        labels = labels_from_metric(metric)

        next unless @block.call(labels) if @block

        stats = metric.get_statistics(
            start_time: Time.now.advance(minutes: -6),
            end_time: Time.now.advance(minutes: -5),
            period: 1,
            statistics: @statistics,
            extended_statistics: @extended_statistics,
            dimensions: metric.dimensions
        )

        stats.datapoints.map do |datapoint|
          datapoint.to_h.select {|k, v| ![:unit, :timestamp].include?(k) }.map do |key, value|
            if (key == :extended_statistics)
              value.map {|e_key, e_value| GreekFire::Metric.new(name, labels.merge({statistic: e_key}), e_value)}
            else
              GreekFire::Metric.new(name, labels.merge({statistic: key}), value)
            end
          end
        end

      end.flatten.compact
    end
  end
end
