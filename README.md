# Asynq

Asynq provides a simple Ruby API for creating Sidekiq background jobs.
It's an alternative to `Sidekiq::Client` which is Ractor-safe.

Note that Asynq does not support any testing modes or batch job creation.

## Installation

Add to your application's Gemfile by executing:

```bash
bundle add asynq
bundle install
```

## Usage

```ruby
# Easy mode, uses the default Redis location
c = Asynq::Client.new
# Note that passing the Job class in directly does not
# provide any benefit.
c.enqueue("MyJob").with_args(123, "mike").now

# Hard mode, configure Redis manually
c = Asynq::Config.new(port: 6380, db: 5).new_client

result = c.enqueue("SomeJob").
  # Keyword arguments are supported with Sidekiq 8.2
  with_args(123, kw1: "foo", kw2: "bar").
  # These options are your typical Sidekiq option hash
  with_options(queue: "high").
  # Schedule the job to execute in one hour
  in(60 * 60)
```