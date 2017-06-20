require "clear_skies/version"
require "securerandom"

require "rails"
require "action_controller/railtie"
require "greek_fire"
require "aws-sdk"

require "clear_skies/app"
require "clear_skies/metrics/cloud_watch/gauge"
require "clear_skies/metrics/cloud_watch/rds_gauge"
require "clear_skies/metrics/cloud_watch/elb_gauge"
require "clear_skies/metrics/cloud_watch/elastic_beanstalk_gauge"
require "clear_skies/request_counter"