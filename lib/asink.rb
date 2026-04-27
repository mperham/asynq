# frozen_string_literal: true

# require_relative "asink/version"
require "redis_client"
require "securerandom"
require "json"

module Asink
  ##
  # Asink provides a lightweight, Ractor-safe Sidekiq client for
  # pushing jobs from any arbitrary Ruby process.
  #
  # Relying on the defaults is simple:
  #
  #   Asink::Client.new
  #
  # Use REDIS_URL to customize the Redis location. More flexible:
  #
  #   c = Asink::Config.new(db: 0, port: 6379, read_timeout: 3).new_client
  #
  class Config
    def initialize(url: ENV["REDIS_URL"], **)
      @cfg = RedisClient.config(url:, **)
    end

    def new_client
      Asink::Client.new(@cfg.new_client)
    end
  end

  ##
  # An Asink::Client can push jobs to Redis
  #
  # ac = Asink::Client.new
  # ac.enqueue(MyJob, "some args", 123).with_options(queue: "easy").now
  # ac.enqueue(MyJob, "some args", 123).with_options(queue: "easy").in(10.minutes)
  #
  #
  class Client
    def initialize(redis = RedisClient.new, &)
      @redis = redis
    end

    Result = Struct.new(:jid, :error) do
      def success?
        error.nil?
      end
    end

    Candidate = Struct.new(:asink, :payload) do
      def in(sec)
        asink.in(sec, payload)
      end

      def now
        asink.now(payload)
      end

      def with_options(**kw)
        payload.merge!(kw.transform_keys(&:to_s))
        self
      end

      def with_args(*args, **kwargs)
        args.append(kwargs.transform_keys(&:to_s)) unless kwargs.empty?
        payload["args"] = args
        self
      end

      def jid = payload["jid"]
    end

    # asink = Asink.new
    # result = asink.enqueue("MyJob").with_args(123, "bob").with_options(queue: "high").in(30.seconds)
    # result = asink.enqueue(MyJob).with_args(123, "bob").now
    def enqueue(klass)
      payload = {}
      payload["jid"] = SecureRandom.hex(12)
      payload["class"] = klass.to_s
      payload["queue"] = "default"
      payload["args"] = []
      payload["created_at"] = now_in_millis

      Candidate.new(self, payload)
    end

    def now(payload)
      payload["enqueued_at"] = now_in_millis
      str = JSON.generate(payload)
      qname = payload["queue"]
      with do |conn|
        conn.multi do |m|
          m.call("sadd", "queues", qname)
          m.call("rpush", "queue:#{qname}", str)
        end
      end
      Result.new(payload["jid"])
    end

    def in(seconds, payload)
      str = JSON.generate(payload)
      at = (Time.now + seconds).to_f.to_s
      with do |conn|
        conn.call("zadd", "schedule", at, str)
      end
      Result.new(payload["jid"])
    end

    def now_in_millis = ::Process.clock_gettime(::Process::CLOCK_REALTIME, :millisecond)
    def with(&) = yield @redis
  end
end
