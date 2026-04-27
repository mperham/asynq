require "test_helper"
require "sidekiq/client"
require "sidekiq/api"

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

  def assert_payload_equal(j1, j2)
    %w[retry queue args].each do |attr|
      assert_equal j1[attr], j2[attr], "Unexpected value for #{attr}"
    end
    %w[created_at enqueued_at jid].each do |attr|
      assert j1.item.has_key?(attr), "Missing #{attr}"
      assert j2.item.has_key?(attr), "Missing #{attr}"
      assert_equal j1[attr].to_s.size, j2[attr].to_s.size
    end
  end
end
