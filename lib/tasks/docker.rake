require 'docker'

namespace :ecr do

  desc "Build and push docker image."
  task "release", [:repo] do |t, args|
    client = Aws::ECR::Client.new
    resp = client.get_authorization_token({}).authorization_data.first
    auth = Base64.decode64 resp.authorization_token

    Docker.authenticate!('username' => auth.split(":").first, 'password' => auth.split(":").second, 'serveraddress' => resp.proxy_endpoint)

    repo = args[:repo]
    image = Docker::Image.build_from_dir('.') do |v|
      v.split("\r\n").each do |line|
        if (log = JSON.parse(line)) && log.has_key?("stream")
          $stdout.write log["stream"]
        end
      end
    end

    image.tag('repo' => File.join(URI(resp.proxy_endpoint).host, repo), 'tag' => ClearSkies::VERSION)

    raise RuntimeError.new("#{repo}:#{ClearSkies::VERSION} already exists!") if client.list_images(repository_name: repo).image_ids.map(&:image_tag).include?(ClearSkies::VERSION)

    image.push do |v|
      v.split("\r\n").each do |line|
        log = JSON.parse(line)
        if log.has_key?("id")
          $stdout.write "#{log["id"]}: "
        end
        if log.has_key?("status")
          $stdout.puts log["status"]
        end
        if log.has_key?("error")
          $stdout.puts log["error"]
        end
      end
    end
  end
end
