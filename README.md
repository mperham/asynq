# Asynq

Asynq provides a simple Ruby API for creating Sidekiq background jobs.
It's a Ractor-safe alternative to `Sidekiq::Client`.

Note that Asynq purposefully does not have many features.
Possible future features:

* Bulk job creation
* Client middleware

Open a new issue and tell us your ideas!

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
  # TODO Keyword arguments are still a work in progress
  # with_args(123, kw1: "foo", kw2: "bar").
  with_args(123, "mike").
  # These options are your typical Sidekiq option hash
  with_options(queue: "high").
  # Schedule the job to execute in one hour
  in(60 * 60)
```