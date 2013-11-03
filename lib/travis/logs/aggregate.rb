require 'travis'
require 'travis/support'
require 'core_ext/kernel/run_periodically'

Travis::Database.connect
Travis::Notification.setup
Travis::Exceptions::Reporter.start

Travis::Async.enabled = true
Travis::Async::Sidekiq.setup(Travis.config.redis.url, Travis.config.sidekiq)

Travis::Metrics.setup
Travis::Notification.setup if Travis.env != 'production'

def aggregate_logs
  Travis.run_service(:logs_aggregate)
rescue Exception => e
  Travis::Exceptions.handle(e)
end

run_periodically(Travis.config.logs.intervals.vacuum || 10) do
  aggregate_logs unless Travis::Features.feature_deactivated?(:log_aggregation)
end.join
