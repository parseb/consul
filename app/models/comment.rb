class Comment < ActiveRecord::Base
  include Flaggable
  include HasPublicAuthor
  include Graphqlable

  acts_as_paranoid column: :hidden_at
  include ActsAsParanoidAliases
  acts_as_votable
  has_ancestry touch: true

  attr_accessor :as_moderator, :as_administrator

  validates :body, presence: true
  validates :user, presence: true

  validates_inclusion_of :commentable_type, in: ["Debate", "Proposal", "Poll::Question", "ProbeOption", "SpendingProposal", "Budget::Investment"]

  validate :validate_body_length

  belongs_to :commentable, -> { with_hidden }, polymorphic: true, counter_cache: true
  belongs_to :user, -> { with_hidden }

  before_save :calculate_confidence_score

  scope :for_render, -> { with_hidden.includes(user: :organization) }
  scope :with_visible_author, -> { joins(:user).where("users.hidden_at IS NULL") }
  scope :not_as_admin_or_moderator, -> { where("administrator_id IS NULL").where("moderator_id IS NULL")}
  scope :sort_by_flags, -> { order(flags_count: :desc, updated_at: :desc) }

  def self.public_for_api
    joins("FULL OUTER JOIN debates ON commentable_type = 'Debate' AND commentable_id = debates.id").
    joins("FULL OUTER JOIN proposals ON commentable_type = 'Proposal' AND commentable_id = proposals.id").
    where("commentable_type = 'Proposal' AND proposals.hidden_at IS NULL OR commentable_type = 'Debate' AND debates.hidden_at IS NULL")
  end

  scope :sort_by_most_voted, -> { order(confidence_score: :desc, created_at: :desc) }
  scope :sort_descendants_by_most_voted, -> { order(confidence_score: :desc, created_at: :asc) }

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_descendants_by_newest, -> { order(created_at: :desc) }

  scope :sort_by_oldest, -> { order(created_at: :asc) }
  scope :sort_descendants_by_oldest, -> { order(created_at: :asc) }

  after_create :call_after_commented

  def self.build(commentable, user, body, p_id=nil)
    new commentable: commentable,
        user_id:     user.id,
        body:        body,
        parent_id:   p_id
  end

  def self.find_commentable(c_type, c_id)
    c_type.constantize.find(c_id)
  end

  def author_id
    user_id
  end

  def author
    user
  end

  def author=(author)
    self.user= author
  end

  def total_votes
    cached_votes_total
  end

  def total_likes
    cached_votes_up
  end

  def total_dislikes
    cached_votes_down
  end

  def as_administrator?
    administrator_id.present?
  end

  def as_moderator?
    moderator_id.present?
  end

  def after_hide
    commentable_type.constantize.with_hidden.reset_counters(commentable_id, :comments)
  end

  def after_restore
    commentable_type.constantize.with_hidden.reset_counters(commentable_id, :comments)
  end

  def reply?
    !root?
  end

  def call_after_commented
    self.commentable.try(:after_commented)
  end

  def self.body_max_length
    Setting['comments_body_max_length'].to_i
  end

  def calculate_confidence_score
    self.confidence_score = ScoreCalculator.confidence_score(cached_votes_total,
                                                             cached_votes_up)
  end

  def self.public_columns_for_api
    ["id",
     "commentable_id",
     "commentable_type",
     "body",
     "created_at",
     "cached_votes_total",
     "cached_votes_up",
     "cached_votes_down",
     "ancestry",
     "confidence_score"]
  end

  def public_for_api?
    return false unless commentable.present?
    return false if commentable.hidden?
    return false unless ["Proposal", "Debate"].include? commentable_type
    return false unless commentable.public_for_api?
    return true
  end

  private

    def validate_body_length
      validator = ActiveModel::Validations::LengthValidator.new(
        attributes: :body,
        maximum: Comment.body_max_length)
      validator.validate(self)
    end

end
