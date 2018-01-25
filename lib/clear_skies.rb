require "clear_skies/version"
require "securerandom"

require "rails"
require "action_controller/railtie"
require "greek_fire"
require "aws-sdk"

require "clear_skies/app"
require "clear_skies/aws/reservation_utilization"
require "clear_skies/aws/cloud_watch/measure"
require "clear_skies/aws/cloud_watch/billing"
require "clear_skies/aws/cloud_watch/rds_gauge"
require "clear_skies/aws/cloud_watch/elb_gauge"
require "clear_skies/aws/cloud_watch/elastic_beanstalk_gauge"
require "clear_skies/aws/cloud_watch/redshift_gauge"
require "clear_skies/aws/cloud_watch/request_counter"
require "clear_skies/bugsnag/project_exception_counter"
require "clear_skies/redis/report"
require "clear_skies/elasticsearch/report"
require "clear_skies/aws/rds_reservation_utilization"
require "clear_skies/jenkins/metrics"
require "clear_skies/gemnasium/alerts"
require "clear_skies/pivotal_tracker/metrics"
