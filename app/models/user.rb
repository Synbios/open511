class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :rememberable,
         #:recoverable, # remove unwanted features
         #:validatable,
         :registerable
  has_many :bookmarks, dependent: :destroy
  has_many :usages, dependent: :destroy

  def add_search_usage_record(ip, status)
    self.usages.create request_type: Usage::SEARCH_REQUEST, ip: ip, status: status
  end

  def add_create_usage_record(ip, status)
    self.usages.create request_type: Usage::CREATE_REQUEST, ip: ip, status: status
  end
end
