class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable,
         :rememberable,
         #:recoverable, # remove unwanted features
         #:validatable,
         :registerable
  has_many :bookmarks, dependent: :destroy
end
