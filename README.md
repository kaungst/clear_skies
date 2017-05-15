# ClearSkies


TODO: Delete this and the text above, and describe your gem

## Installation

Install it yourself as:

    $ gem install clear_skies

## Configuration
(from https://github.com/aws/aws-sdk-ruby)
You need to configure `:credentials` and a `:region` to make API calls. It is recommended that you provide these via your environment. This makes it easier to rotate credentials and it keeps your secrets out of source control.

The SDK searches the following locations for credentials:

* `ENV['AWS_ACCESS_KEY_ID']` and `ENV['AWS_SECRET_ACCESS_KEY']`
* Unless `ENV['AWS_SDK_CONFIG_OPT_OUT']` is set, the shared configuration files (`~/.aws/credentials` and `~/.aws/config`) will be checked for a `role_arn` and `source_profile`, which if present will be used to attempt to assume a role.
* The shared credentials ini file at `~/.aws/credentials` ([more information](http://blogs.aws.amazon.com/security/post/Tx3D6U6WSFGOK2H/A-New-and-Standardized-Way-to-Manage-Credentials-in-the-AWS-SDKs))
    * Unless `ENV['AWS_SDK_CONFIG_OPT_OUT']` is set, the shared configuration ini file at `~/.aws/config` will also be parsed for credentials.
* From an instance profile when running on EC2, or from the ECS credential provider when running in an ECS container with that feature enabled.

The SDK searches the following locations for a region:

* `ENV['AWS_REGION']`
* Unless `ENV['AWS_SDK_CONFIG_OPT_OUT']` is set, the shared configuration files (`~/.aws/credentials` and `~/.aws/config`) will also be checked for a region selection.

**The region is used to construct an SSL endpoint**. If you need to connect to a non-standard endpoint, you may specify the `:endpoint` option.

## Usage

To run the exporter simple do:
    $ clear_skies metrics_file

The metrics_file is a ruby script that registers the metrics you wish to export.

``` ruby
# To grab a generic cloudwatch metric use the following method:
ClearSkies::Gauge.register(namespace, metric_name,dimensions, statistics) do |labels|
  labels[:extra] = "label"
  labels[:instance_id] == "something specific"
end

If you pass a block, it will be called for each dimension retrieved.  The block will be passed a hash of all computed labels, and you may add more if you wish.  If the blocks value is false, that dimension will be skipped.

``` ruby
# To grab an RD
ClearSkies::RDSGauge.register("ReadThroughput", ["DBInstanceIdentifier"], ["Average", "Minimum", "Maximum"]) do |labels|
  labels[:environment] == "production"
end
```

There is a helper class for grabbing RDS metrics.  It behaves the same as ClearSkies::Gauge, except that it automatically adds the vpc_id and tags attached.

## Contributing.

If there is a namespace of metrics you wish to add, please submit a PR.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

