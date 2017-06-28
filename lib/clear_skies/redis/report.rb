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

      attr_reader :host, :port, :extra_labels, :metrics
      def initialize(host, port, extra_labels)
        @host = host
        @port = port
        @extra_labels = extra_labels
        GreekFire::Measure.before_metrics { refresh }
      end

      def redis_metrics(database)
        redis = ::Redis.new(host: @host, port: @port, db: database)
        redis_info = redis.info
        metrics = OpenStruct.new
        metrics.host = @host
        metrics.port = @port
        metrics.db = database
        metrics.keys = redis.dbsize
        metrics.last_save = Time.now.to_i - redis.lastsave
        metrics.uptime = redis_info["uptime_in_seconds"].to_f
        metrics.connected_clients =  redis_info["connected_clients"].to_i
        metrics.blocked_clients =  redis_info["blocked_clients"].to_i
        metrics.used_memory =  redis_info["used_memory"].to_f
        metrics.mem_fragmentation_ratio =  redis_info["mem_fragmentation_ratio"].to_f
        metrics.rdb_changes_since_last_save =  redis_info["rdb_changes_since_last_save"].to_f
        metrics.rdb_last_bgsave_time_sec =  redis_info["rdb_last_bgsave_time_sec"].to_f
        metrics.total_commands_processed =  redis_info["total_commands_processed"].to_f
        metrics
      end

      def refresh
        databases = ::Redis.new(:host => @host, :port => @port).info.keys.map {|k| k =~ /^db/ && k.sub("db", "")}.compact
        @metrics = databases.map do |database|
          redis_metrics(database)
        end
      end

    end

    class Measure < GreekFire::Measure
      def initialize(name, &block)
        super(name) do |label|
          block.call(label.delete(:metric))
        end
      end


      def labels
        ClearSkies::Redis::Report.reports.map do |report|
          report.metrics.map do |metric|
            report.extra_labels.merge({host: report.host, port: report.port, db: metric.db, metric: metric })
          end
        end.flatten
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

GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_keys")                        { |metrics| metrics.keys })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_last_save")                   { |metrics| metrics.last_save })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_uptime")                      { |metrics| metrics.uptime })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_connected_clients")           { |metrics| metrics.connected_clients })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_blocked_clients")             { |metrics| metrics.blocked_clients })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_used_memory")                 { |metrics| metrics.used_memory })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_mem_fragmentation_ratio")     { |metrics| metrics.mem_fragmentation_ratio })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_rdb_changes_since_last_save") { |metrics| metrics.rdb_changes_since_last_save })
GreekFire::Metric.register(ClearSkies::Redis::Gauge.new("redis_rdb_last_bgsave_time_sec")    { |metrics| metrics.rdb_last_bgsave_time_sec })
GreekFire::Metric.register(ClearSkies::Redis::Counter.new("redis_total_commands_processed")  { |metrics| metrics.total_commands_processed })
