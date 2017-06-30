module Abilities
  class Everyone
    include CanCan::Ability

    def initialize(user)
      can [:read, :map], Debate
      can [:read, :map, :summary, :share], Proposal
      can :read, Comment

      can [:read, :welcome, :select_district], SpendingProposal
      can [:stats, :results], SpendingProposal

      can :read, Poll
      can :read, Poll::Question

      can [:read, :welcome], Budget
      can :read_results, Budget, phase: "finished"
      can [:read, :print], Budget::Investment
      can [:read], Budget::Group

      can :read, SpendingProposal
      can :read, LegacyLegislation
      can :read, User
      can [:search, :read], Annotation

      can :new, DirectMessage

      can :results_2017, Poll
      can :stats_2017, Poll
      can :info_2017, Poll

      can [:read, :debate, :draft_publication, :allegations, :result_publication], Legislation::Process, published: true

      can [:read], Budget
      can [:read], Budget::Group
      can [:read, :print], Budget::Investment
      can :read_results, Budget, phase: "finished"
      can :read_stats, Budget, phase: ['reviewing_ballots', 'finished']

      can [:read, :changes, :go_to_version], Legislation::DraftVersion
      can [:read], Legislation::Question
      can [:create], Legislation::Answer
      can [:search, :comments, :read, :create, :new_comment], Legislation::Annotation
    end
  end
end
