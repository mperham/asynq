require "test_helper"
require "sidekiq/client"
require "sidekiq/api"

Sidekiq.strict_args!(false)

class TestSidekiq < BaseTest
  def test_client_compatibility
    q = Sidekiq::Queue.new
    assert_equal 0, q.size

    s = Sidekiq::Client.new
    s.push("class" => "MyJob", "args" => [123, "mike"])
    job1 = q.first
    q.clear
    assert_equal 0, q.size

    asynq.enqueue("MyJob").with_args(123, "mike").now
    job2 = q.first
    q.clear

    assert_payload_equal job1, job2
  end

  def test_kwargs
    q = Sidekiq::Queue.new
    assert_equal 0, q.size

    s = Sidekiq::Client.new
    s.push("class" => "MyJob", "args" => [123, "mike", foo: "bar"])
    job1 = q.first
    q.clear
    assert_equal 0, q.size

    asynq.enqueue("MyJob").with_args(123, "mike", foo: "bar").now
    job2 = q.first
    q.clear

    assert_payload_equal job1, job2
  end

  EXTRA_KEYS = %w[flavor]

  def assert_payload_equal(s, a)
    assert_equal s.item.keys.sort, (a.item.keys - EXTRA_KEYS).sort
    assert_equal "aq", a["flavor"]

    %w[retry queue args].each do |attr|
      assert_equal s[attr], a[attr], "Unexpected value for #{attr}"
    end

    %w[created_at enqueued_at jid].each do |attr|
      assert s.item.has_key?(attr), "Missing #{attr}"
      assert a.item.has_key?(attr), "Missing #{attr}"
      assert_equal s[attr].to_s.size, a[attr].to_s.size
    end
  end
end
