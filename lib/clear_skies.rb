require "clear_skies/version"
require "securerandom"

require "rails"
require "action_controller/railtie"
require "greek_fire"
require "aws-sdk"

require "clear_skies/app"
require "clear_skies/metrics/gauge"
require "clear_skies/metrics/rds_gauge"
