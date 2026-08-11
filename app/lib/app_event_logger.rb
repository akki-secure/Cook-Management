module AppEventLogger
  def self.log(event:, user: nil, **fields)
    Rails.logger.info({
      log_type: "app_event",
      event: event,
      user_id: user&.id,
      logged_at: Time.current.iso8601,
      **fields
    }.to_json)
  end
end
