# frozen_string_literal: true

require "test_helper"

class TestAsink < BaseTest
  def test_enqueue_now
    result = asink.enqueue("MyJob").with_args(123, "bob").with_options(queue: "high").now
    refute_nil result
    assert_equal 24, result.jid.size
    assert_nil result.error

    payload = helper.first_in(:high)
    refute_nil payload
    assert_equal "MyJob", payload["class"]
    assert_equal "high", payload["queue"]
    assert_equal [123, "bob"], payload["args"]
  end

  def test_kwargs
    result = asink.enqueue("MyJob").with_args(123, "bob", foo: "bar").now
    refute_nil result
    assert_equal 24, result.jid.size
    assert_nil result.error

    payload = helper.first_job
    refute_nil payload
    assert_equal "MyJob", payload["class"]
    assert_equal [123, "bob", {"foo" => "bar"}], payload["args"]
  end

  def test_enqueue_in
    start = Time.now.to_f

    result = asink.enqueue("MyJob").with_args(123, "bob").in(120)
    refute_nil result
    assert_equal 24, result.jid.size
    assert_nil result.error
    assert result.success?

    at, payload = helper.first_scheduled
    refute_nil payload
    assert_equal "MyJob", payload["class"]
    assert_equal "default", payload["queue"]
    assert_equal [123, "bob"], payload["args"]
    assert_in_delta start + 120, at.to_f, 0.1
  end

  def test_configure
    c = Asink::Config.new(read_timeout: 1, db: 3)
    asink = c.new_client
    refute_nil asink
  end

  def test_ractor
    r = Ractor.new do
      asink = Asink::Client.new(RedisClient.new)
      asink.enqueue("MyRactorJob").with_args(123, "bob").in(120)
    end
    r.value

    at, payload = helper.first_scheduled
    refute_nil payload
    refute_nil at
    assert_equal "MyRactorJob", payload["class"]
    assert_equal "default", payload["queue"]
    assert_equal [123, "bob"], payload["args"]
  end

  def test_config
    Asink::Config.new(db: 4, port: 6380).new_client
  end
end
