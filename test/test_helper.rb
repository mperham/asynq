# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "asink"
require "redis_helper"

require "minitest/autorun"

class BaseTest < Minitest::Test
  attr_reader :helper
  attr_reader :asink

  def setup
    @helper = RedisHelper.new.tap do |redis|
      redis.flush
    end

    @asink = Asink::Client.new(RedisClient.new)
  end
end
