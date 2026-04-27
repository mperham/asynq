# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "asynq"
require "redis_helper"

require "minitest/autorun"

class BaseTest < Minitest::Test
  attr_reader :helper
  attr_reader :asynq

  def setup
    @helper = RedisHelper.new.tap do |redis|
      redis.flush
    end

    @asynq = Asynq::Client.new(RedisClient.new)
  end
end
