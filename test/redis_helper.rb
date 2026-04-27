require "json"

class RedisHelper
  def initialize
    @redis = RedisClient.new
  end

  def flush
    @redis.call("flushdb")
  end

  def first_in(q = :default)
    s = @redis.call("lindex", "queue:#{q}", 0)
    JSON.parse(s) if s
  end
  alias_method :first_job, :first_in

  def first_scheduled
    ex = @redis.call("zrange", "schedule", 0, 0, "withscores").first
    (str, tm) = ex
    [Time.at(tm), JSON.parse(str)]
  end
end
