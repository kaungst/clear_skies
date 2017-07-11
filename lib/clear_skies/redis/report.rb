require 'redis'

module ClearSkies
  module Redis

    class Report

      def self.register(host, port, extra_labels=nil)
        reports << ClearSkies::Redis::Report.new(host, port, extra_labels || Hash.new)
      end

      def self.reports
        @reports ||= []
      end

      attr_reader :host, :port, :extra_labels
      def initialize(host, port, extra_labels)
        @host = host
        @port = port
        @extra_labels = {host: host, port: port}.merge extra_labels
      end

      def self.metric_names
        [
            "keys",
            "last_save",
            "uptime",
            "connected_clients",
            "blocked_clients",
            "used_memory",
            "mem_fragmentation_ratio",
            "rdb_changes_since_last_save",
            "rdb_last_bgsave_time_sec",
            "total_commands_processed"
        ]
      end

      def dimensions
        ::Redis.new(:host => @host, :port => @port).info.keys.map {|k| k =~ /^db/ && k.sub("db", "")}.compact
      end

      def report_dimensions
        dimensions.map do |dimension|
          ReportDimension.new(self, dimension)
        end
      end

      def items
        report_dimensions.map
      end
    end

    class ReportDimension
      attr_reader :report, :dimension

      def initialize(report, dimension)
        @report = report
        @dimension = dimension
      end

      def metrics
        redis = ::Redis.new(host: report.host, port: report.port, db: @dimension)
        redis_info = redis.info

        metrics = OpenStruct.new
        metrics.keys = redis.dbsize
        metrics.last_save = Time.now.to_i - redis.lastsave
        metrics.uptime = redis_info["uptime_in_seconds"].to_f
        metrics.connected_clients =  redis_info["connected_clients"].to_i
        metrics.blocked_clients =  redis_info["blocked_clients"].to_i
        metrics.used_memory =  redis_info["used_memory"].to_f
        metrics.mem_fragmentation_ratio =  redis_info["mem_fragmentation_ratio"].to_f
        metrics.rdb_changes_since_last_save =  redis_info["rdb_changes_since_last_save"].to_f
        metrics.rdb_last_bgsave_time_szec =  redis_info["rdb_last_bgsave_time_sec"].to_f
        metrics.total_commands_processed =  redis_info["total_commands_processed"].to_f
        metrics
      end
    end

    class Measure < GreekFire::Measure
      def initialize(report_dimensions, prefix, name)
        @report_dimensions = report_dimensions
        super("#{prefix}_#{name}") do |label|
          label.delete(:metric).metrics.to_h[name.to_sym]
        end
      end


      def labels
        @report_dimensions.map do |report_dimension|
          report_dimension.report.extra_labels.merge({metric: report_dimension })
        end
      end
    end

    class Gauge < ClearSkies::Redis::Measure
      def to_partial_path
        GreekFire::Gauge._to_partial_path
      end
    end
    class Counter < ClearSkies::Redis::Measure
      def to_partial_path
        GreekFire::Counter._to_partial_path
      end
    end
  end
end

GreekFire::Metric.register do
  report_dimensions = ClearSkies::Redis::Report.reports.map(&:report_dimensions).flatten
  next [] unless report_dimensions.length > 0

  ClearSkies::Redis::Report.metric_names.map do |metric_name|
    ClearSkies::Redis::Gauge.new(report_dimensions,  "redis", metric_name)
  end
end

