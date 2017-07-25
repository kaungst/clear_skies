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

      def dimensions
        ::Redis.new(:host => @host, :port => @port).info.keys.map {|k| k =~ /^db/ && k.sub("db", "")}.compact
      end

      def report_dimensions
        dimensions.map do |dimension|
          ReportDimension.new(self, dimension)
        end
      end
    end

    class MeasureSet < GreekFire::MeasureSet
      def items
        labels = ClearSkies::Redis::Report.reports.map do | report|
          report.report_dimensions.map do |report_dimension|
            GreekFire::SmartLabel.new(report_dimension.metrics, report_dimension.extra_labels)
          end
        end.flatten

        return [] unless labels.length > 0

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
        ].map do |metric_name|
          GreekFire::Gauge.new("redis_#{metric_name}", labels: labels) do |label|
            label.value[metric_name.to_sym]
          end
        end
      end
    end

    class ReportDimension
      attr_reader :report, :dimension

      def initialize(report, dimension)
        @report = report
        @dimension = dimension
        @extra_labels = { db: dimension }
      end

      def extra_labels
        @report.extra_labels.merge(@extra_labels)
      end

      def metrics
        redis = ::Redis.new(host: report.host, port: report.port, db: @dimension)
        redis_info = redis.info

        metrics = HashWithIndifferentAccess.new
        metrics[:keys ]= redis.dbsize
        metrics[:last_save ]= Time.now.to_i - redis.lastsave
        metrics[:uptime ]= redis_info["uptime_in_seconds"].to_f
        metrics[:connected_clients ]=  redis_info["connected_clients"].to_i
        metrics[:blocked_clients ]=  redis_info["blocked_clients"].to_i
        metrics[:used_memory ]=  redis_info["used_memory"].to_f
        metrics[:mem_fragmentation_ratio ]=  redis_info["mem_fragmentation_ratio"].to_f
        metrics[:rdb_changes_since_last_save ]=  redis_info["rdb_changes_since_last_save"].to_f
        metrics[:rdb_last_bgsave_time_szec ]=  redis_info["rdb_last_bgsave_time_sec"].to_f
        metrics[:total_commands_processed ]=  redis_info["total_commands_processed"].to_f
        metrics
      end
    end
  end
end

GreekFire::Metric.register ClearSkies::Redis::MeasureSet.new

