require 'redis'
module ClearSkies
  module Redis
    class Report
      def self.register(host, port, extra_labels=nil)
        extra_labels = Hash.new unless extra_labels

        r = ClearSkies::Redis::Report.new(host, port)
        databases = Proc.new { ::Redis.new(:host => host, :port => port).info.keys.map {|k| k =~ /^db/ && k.sub("db", "")}.compact }

        GreekFire::Gauge.register("redis_keys",                        labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).keys }
        GreekFire::Gauge.register("redis_last_save",                   labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).last_save }
        GreekFire::Gauge.register("redis_uptime",                      labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).uptime }
        GreekFire::Gauge.register("redis_connected_clients",           labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).connected_clients }
        GreekFire::Gauge.register("redis_blocked_clients",             labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).blocked_clients }
        GreekFire::Gauge.register("redis_used_memory",                 labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).used_memory }
        GreekFire::Gauge.register("redis_mem_fragmentation_ratio",     labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).mem_fragmentation_ratio }
        GreekFire::Gauge.register("redis_rdb_changes_since_last_save", labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).rdb_changes_since_last_save }
        GreekFire::Gauge.register("redis_rdb_last_bgsave_time_sec",    labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).rdb_last_bgsave_time_sec }
        GreekFire::Counter.register("redis_total_commands_processed",  labels: {"database" => databases} ) { | labels| labels.merge!(extra_labels);r.redis_metrics(labels).total_commands_processed }
      end


      def redis_metrics(labels)
        cache_key = "redis_stats_#{@host}_#{@port}_#{labels["database"]}"
        Rails.cache.fetch(cache_key, expires_in: 1.second) do
          redis = ::Redis.new(host: @host, port: @port, db: labels["database"])
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

      private
      def initialize(host, port)
        @host = host
        @port = port
      end
    end
  end
end
