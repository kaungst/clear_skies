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

      def indicies
        client = ::Elasticsearch::Client.new(hosts: @url)
        client.indices.get_aliases
      end

      def report_indicies
        indicies.map do |index|
          ReportIndex.new(self, index)
        end
      end

      def nodes
        client = ::Elasticsearch::Client.new(hosts: @url)
        client.nodes.stats["nodes"]
      end

      def report_nodes
        nodes.map do |node_name, node_props|
          ReportNode.new(self, node_name, node_props)
        end
      end
    end

    class ReportIndex
      attr_reader :report, :index

      def initialize(report, index)
        @report = report
        @index = index
        @extra_labels = { index: index_alias }
      end

      def index_alias
        @index[1]["aliases"].keys&.first || @index[0]
      end

      def index_name
        @index[0]
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

    class ReportNode
      attr_reader :report, :extra_labels

      def initialize(report, node_name, node_props)
        @report = report
        @node_props = node_props
        @extra_labels = { node_name: node_name }
      end

      def extra_labels
        @report.extra_labels.merge(@extra_labels)
      end

      def metrics
        ClearSkies::Elasticsearch::Report.flatten_hash(@node_props, "elasticsearch_node")
      end

    end


    class MeasureSet < GreekFire::MeasureSet
      def items
        metrics = []

        ### Cluster Metrics ##
        labels = ClearSkies::Elasticsearch::Report.reports.map do | report|
          GreekFire::SmartLabel.new(report.metrics, report.extra_labels)
        end

        metric_names = labels.map {|i| i.value.keys}.flatten.uniq

        metric_names.each do |metric|
          metrics << GreekFire::Gauge.new(metric, labels: labels) do |label|
            label.value[metric]
          end
        end

        ### Index Metrics
        labels = ClearSkies::Elasticsearch::Report.reports.map do | report|
          report.report_indicies.map do |report_index|
            GreekFire::SmartLabel.new(report_index.metrics, report_index.extra_labels)
          end
        end.flatten

        metric_names = labels.map {|i| i.value.keys}.flatten.uniq

        metric_names.each do |metric|
          metrics << GreekFire::Gauge.new(metric, labels: labels) do |label|
            label.value[metric]
          end
        end

        ### Node Metrics
        labels = ClearSkies::Elasticsearch::Report.reports.map do | report|
          report.report_nodes.map do |report_node|
            GreekFire::SmartLabel.new(report_node.metrics, report_node.extra_labels)
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

  end
end

GreekFire::Metric.register ClearSkies::Elasticsearch::MeasureSet.new
