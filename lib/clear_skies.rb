require "clear_skies/version"
require "securerandom"

require "rails"
require "action_controller/railtie"
require "greek_fire"
require "aws-sdk"

require "clear_skies/app"
require "clear_skies/aws/reservation_utilization"
require "clear_skies/aws/cloud_watch/gauge"
require "clear_skies/aws/cloud_watch/billing"
require "clear_skies/aws/cloud_watch/rds_gauge"
require "clear_skies/aws/cloud_watch/elb_gauge"
require "clear_skies/aws/cloud_watch/elastic_beanstalk_gauge"
require "clear_skies/aws/cloud_watch/redshift_gauge"
require "clear_skies/aws/cloud_watch/request_counter"
require "clear_skies/redis/report"
require "clear_skies/elasticsearch/report"