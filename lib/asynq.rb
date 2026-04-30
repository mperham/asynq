# frozen_string_literal: true

# require_relative "asynq/version"
require "redis_client"
require "securerandom"
require "json"

require "asynq/version"
require "asynq/flavor"

module Asynq
  ##
  # Asynq provides a lightweight, Ractor-safe Sidekiq client for
  # pushing jobs from any arbitrary Ruby process.
  #
  # Relying on the defaults is simple:
  #
  #   Asynq::Client.new
  #
  # Use REDIS_URL to customize the Redis location. More flexible:
  #
  #   c = Asynq::Config.new(db: 0, port: 6379, read_timeout: 3).new_client
  #
  class Config
    def initialize(url: ENV["REDIS_URL"], **)
      @cfg = RedisClient.config(url:, **)
    end

    def new_client
      Asynq::Client.new(@cfg.new_client)
    end
  end

  ##
  # An Asynq::Client can push jobs to Redis
  #
  #   ac = Asynq::Config.new(**redis_options).new_client
  #   ac = Asynq::Client.new # use the defaults
  #
  # As long as you start with +enqueue(klass)+, the API allows
  # a variety of calling patterns, allowing you to compose your
  # jobs fluently.
  #
  #   ac.enqueue(MyJob).with_args("something", 123).with_options(queue: "easy").now
  #   ac.enqueue("MyJob").with_options(queue: "easy").perform("something", 123).in(10.minutes)
  #
  #
  class Client
    def initialize(redis = RedisClient.new, &)
      @redis = redis
    end

    Result = Data.define(:jid, :error) do
      def success?
        error.nil?
      end
    end

    Candidate = Data.define(:asynq, :payload) do
      def in(sec)
        asynq.in(sec, payload)
      end

      def now
        asynq.now(payload)
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
      alias_method :perform, :with_args

      def jid = payload["jid"]
    end

    # asynq = Asynq.new
    # result = asynq.enqueue("MyJob").with_args(123, "bob").with_options(queue: "high").in(30.seconds)
    # result = asynq.enqueue(MyJob).with_args(123, "bob").now
    def enqueue(klass)
      payload = {}
      payload["jid"] = SecureRandom.hex(12)
      payload["class"] = klass.to_s
      payload["queue"] = "default"
      payload["args"] = []
      payload["retry"] = true
      payload["flavor"] = "aq"
      payload["created_at"] = now_in_millis

      Candidate.new(asynq: self, payload:)
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
      Result.new(jid: payload["jid"], error: nil)
    end

    def in(seconds, payload)
      str = JSON.generate(payload)
      at = (Time.now + seconds).to_f.to_s
      with do |conn|
        conn.call("zadd", "schedule", at, str)
      end
      Result.new(jid: payload["jid"], error: nil)
    end

    def now_in_millis = ::Process.clock_gettime(::Process::CLOCK_REALTIME, :millisecond)
    def with(&) = yield @redis
  end
end
