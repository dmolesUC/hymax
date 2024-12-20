class AddDefaultUsers < ActiveRecord::Migration[6.1]
  DEFAULT_USER_EMAIL_ADDRESSES = %w[archivist1@example.test dev@example.test].freeze

  def up
    DEFAULT_USER_EMAIL_ADDRESSES.each do |email|
      User.create!(email: email, password: "password")
    end
  end

  def down
    User.where(email: DEFAULT_USER_EMAIL_ADDRESSES).destroy_all
  end
end
