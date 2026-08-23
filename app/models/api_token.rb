class ApiToken < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true

  # 生トークンは発行時にしか手に入らない（DBにはdigestのみ保存）
  attr_reader :plain_token

  def self.issue!(user)
    raw = SecureRandom.hex(32)
    record = create!(user: user, token_digest: digest(raw))
    record.instance_variable_set(:@plain_token, raw)
    record
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    token = find_by(token_digest: digest(raw_token))
    token&.touch(:last_used_at)
    token&.user
  end

  def self.digest(raw_token)
    Digest::SHA256.hexdigest(raw_token)
  end
end
