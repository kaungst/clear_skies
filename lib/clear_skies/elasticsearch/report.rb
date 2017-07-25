require 'elasticsearch'
require 'uri'

module ClearSkies
  module Elasticsearch
    class Report

      def self.register(url, extra_labels=nil)
        reports << ClearSkies::Elasticsearch::Report.new(url, extra_labels || Hash.new)
      end

      def self.reports
        @reports ||= []
      end


      def self.flatten_hash(hash, prefix="elasticsearch")
        ret = HashWithIndifferentAccess.new
        hash.each do |k, value|
          name = "#{prefix}_#{k}"
          if value.is_a?(Hash)
            ret.merge!(flatten_hash(value, name))
          elsif(value.is_a?(Numeric))
            ret[name] = value
          end
        end
        return ret
      end

      attr_reader :url, :extra_labels
      def initialize(url, extra_labels)
        @url = url

        @extra_labels = {host: URI(url).host}.merge extra_labels
      end

      def metrics
        client = ::Elasticsearch::Client.new(hosts: url)
        stats = client.cluster.stats
        ClearSkies::Elasticsearch::Report.flatten_hash(stats)
      end

      def dimensions
        client = ::Elasticsearch::Client.new(hosts: @url)
        client.indices.get_aliases
      end

      def report_dimensions
        dimensions.map do |dimension|
          ReportDimension.new(self, dimension)
        end
      end
    end

    class MeasureSet < GreekFire::MeasureSet
      def items
        metrics = []

        labels = ClearSkies::Elasticsearch::Report.reports.map do | report|
          GreekFire::SmartLabel.new(report.metrics, report.extra_labels)
        end

        metric_names = labels.map {|i| i.value.keys}.flatten.uniq

        metric_names.each do |metric|
          metrics << GreekFire::Gauge.new(metric, labels: labels) do |label|
            label.value[metric]
          end
        end

        labels = ClearSkies::Elasticsearch::Report.reports.map do | report|
          report.report_dimensions.map do |report_dimension|
            GreekFire::SmartLabel.new(report_dimension.metrics, report_dimension.extra_labels)
          end
        end.flatten

        metric_names = labels.map {|i| i.value.keys}.flatten.uniq

        metric_names.each do |metric|
          metrics << GreekFire::Gauge.new(metric, labels: labels) do |label|
            label.value[metric]
          end
        end
        metrics
      end
    end

    class ReportDimension
      attr_reader :report, :dimension, :extra_labels

      def initialize(report, dimension)
        @report = report
        @dimension = dimension
        @extra_labels = { index: index_alias(dimension) }
      end

      def index_alias(dimension)
        @dimension[1]["aliases"].keys&.first || @dimension[0]
      end

      def index_name
        @dimension[0]
      end

      def extra_labels
        @report.extra_labels.merge(@extra_labels)
      end


      def metrics
        client = ::Elasticsearch::Client.new(hosts: report.url)
        stats = client.indices.stats["indices"][index_name]["total"]
        ClearSkies::Elasticsearch::Report.flatten_hash(stats)
      end
    end
  end
end

GreekFire::Metric.register ClearSkies::Elasticsearch::MeasureSet.new
