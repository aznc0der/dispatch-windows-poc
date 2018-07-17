# frozen_string_literal: true

class Order < ApplicationRecord
  LOTTERY_INTERVAL_SEC = ENV['DISPATCH_WINDOW_SECOND']&.to_i || 10
  include AASM

  after_create :push_lottery_message

  aasm column: 'status' do
    state :pending, initial: true
    state :picked

    event :pick do
      transitions from: :pending, to: :picked
    end
  end

  private

  def push_lottery_message
    redis = NEW_REDIS_CLIENT
    redis.publish("order:#{id}:request", 'start_lottery')
    redis.set("order:#{id}:lottery_end_time", lottery_end_time)
  end

  def lottery_end_time
    ((Time.current.to_f + LOTTERY_INTERVAL_SEC) * 1000).to_i # store with millisecond, as the timeframe is small therefore milliseconds should count
  end
end
