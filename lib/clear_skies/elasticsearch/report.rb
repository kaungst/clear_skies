require 'elasticsearch'

module ClearSkies
  module Elasticsearch
    class Report

      def self.register(url, extra_labels=nil)
        reports << ClearSkies::Elasticsearch::Report.new(url, extra_labels || Hash.new)
      end

      def self.reports
        @reports ||= []
      end

      attr_reader :url, :extra_labels, :metrics
      def initialize(url, extra_labels)
        @url = url
        @extra_labels = extra_labels
        GreekFire::Measure.before_metrics { refresh }
      end

      def elasticsearch_metrics(client, index)
        metrics = OpenStruct.new
        metrics.index = index
        stats = client.indices.stats["indices"][index]["total"]
        metrics.docs_count = stats["docs"]["count"]
        metrics.docs_deleted = stats["docs"]["deleted"]
        metrics
      end

      def refresh
        client = ::Elasticsearch::Client.new(hosts: @url)
        aliases = client.indices.get_aliases

        @metrics = aliases.map do |index, _aliases|
          elasticsearch_metrics(client, index)
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
        ClearSkies::Elasticsearch::Report.reports.map do |report|
          report.metrics.map do |metric|
            report.extra_labels.merge({index: metric.index, metric: metric })
          end
        end.flatten
      end
    end

    class Gauge < ClearSkies::Elasticsearch::Measure
      def to_partial_path
        GreekFire::Gauge._to_partial_path
      end
    end
    class Counter < ClearSkies::Elasticsearch::Measure
      def to_partial_path
        GreekFire::Counter._to_partial_path
      end
    end
  end
end

# GreekFire::Metric.register(ClearSkies::Elasticsearch::Gauge.new("elasticsearch_docs_count")                     { |metrics| metrics.docs_count })
# GreekFire::Metric.register(ClearSkies::Elasticsearch::Gauge.new("elasticsearch_docs_deleted")                   { |metrics| metrics.docs_deleted })


#For a <DIM>, grab N metrics.