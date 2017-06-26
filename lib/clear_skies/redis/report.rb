require 'redis'
module ClearSkies
  module Redis
    class Report

      def self.register(host, port, extra_labels=nil)
        extra_labels = Hash.new unless extra_labels


        hosts << {host: host, port: port, extra_labels: extra_labels }
      end

      def self.hosts
        @hosts ||= []
      end

      def self.redis_metrics(host, port, database)
        cache_key = "redis_stats_#{host}_#{port}_#{database}"
        Rails.cache.fetch(cache_key, expires_in: 1.second) do
          redis = ::Redis.new(host: host, port: port, db: database)
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
          metrics.rdb_last_bgsave_time_sec =  redis_info["rdb_last_bgsave_time_sec"].to_f
          metrics.total_commands_processed =  redis_info["total_commands_processed"].to_f
          metrics
        end
      end
    end

    private

    class Measure < GreekFire::Measure
      def initialize(name, &block)
        super(name)

        @block = block
      end

      def metrics
        ClearSkies::Redis::Report.hosts.map do |doc|
          host = doc[:host]
          port = doc[:port]
          databases = ::Redis.new(:host => host, :port => port).info.keys.map {|k| k =~ /^db/ && k.sub("db", "")}.compact

          databases.map do |database|
            value = @block.call(ClearSkies::Redis::Report.redis_metrics(host, port, database))
            GreekFire::Metric.new(name, {host: host, port: port, db: database}.merge(doc[:extra_labels]), value)
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
