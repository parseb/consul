class ProposalNotification < ActiveRecord::Base

  include Graphqlable
  
  belongs_to :author, class_name: 'User', foreign_key: 'author_id'
  belongs_to :proposal

  validates :title, presence: true
  validates :body, presence: true
  validates :proposal, presence: true
  validate :minimum_interval

  def self.public_for_api
    joins(:proposal).where("proposals.hidden_at IS NULL")
  end

  def minimum_interval
    return true if proposal.try(:notifications).blank?
    if proposal.notifications.last.created_at > (Time.current - Setting[:proposal_notification_minimum_interval_in_days].to_i.days).to_datetime
      errors.add(:title, I18n.t('activerecord.errors.models.proposal_notification.attributes.minimum_interval.invalid', interval: Setting[:proposal_notification_minimum_interval_in_days]))
    end
  end

  def self.public_columns_for_api
    ["title",
     "body",
     "proposal_id",
     "created_at"]
  end

  def public_for_api?
    return false unless proposal.present?
    return false if proposal.hidden?
    return false unless proposal.public_for_api?
    return true
  end

end
