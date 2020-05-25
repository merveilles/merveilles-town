enabled         = ENV['ES_ENABLED'] == 'true'
host            = ENV.fetch('ES_HOST') { 'localhost' }
port            = ENV.fetch('ES_PORT') { 9200 }
fallback_prefix = ENV.fetch('REDIS_NAMESPACE') { nil }
prefix          = ENV.fetch('ES_PREFIX') { fallback_prefix }

Chewy.settings = {
  host: "#{host}:#{port}",
  prefix: prefix,
  enabled: enabled,
  journal: false,
  sidekiq: { queue: 'pull' },
}

Chewy.root_strategy              = :custom_sidekiq
Chewy.request_strategy           = :custom_sidekiq
Chewy.use_after_commit_callbacks = false

module Chewy
  class << self
    def enabled?
      settings[:enabled]
    end
  end
end

# ElasticSearch uses Faraday internally. Faraday interprets the
# http_proxy env variable by default which leads to issues when
# Mastodon is run with hidden services enabled, because
# ElasticSearch is *not* supposed to be accessed through a proxy
Faraday.ignore_env_proxy = true
