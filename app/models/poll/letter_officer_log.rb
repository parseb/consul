class Poll
  class LetterOfficerLog < ActiveRecord::Base
    VALID_MESSAGES = { ok: "Voto VÁLIDO",
                       has_voted: "Voto REFORMULADO",
                       census_failed: "Voto NO VÁLIDO" }

    belongs_to :user

    validates :message, presence: true
    validates :message, inclusion: {in: VALID_MESSAGES.values}
    validates :user_id, presence: true

    def self.log(user, document, postal_code, msg)
      ::Poll::LetterOfficerLog.create(user: user, document_number: document, postal_code: postal_code, message: VALID_MESSAGES[msg])
    end

  end
end
