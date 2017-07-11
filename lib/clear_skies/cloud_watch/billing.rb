module ClearSkies
  module CloudWatch
    class Billing < ClearSkies::CloudWatch::Gauge
      def initialize(dimension, statistics, description: nil, &block)
        super("AWS/Billing", "EstimatedCharges", dimension, statistics, description: description, aws_parameters: {start_time: {days: -1}, end_time: {minutes: -5}, period: 60*60*24}, &block)
      end


      def self.cloudwatch_client
        @client ||= Aws::CloudWatch::Client.new(region: "us-east-1")
      end
    end
  end
end