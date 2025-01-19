# frozen_string_literal: true

class MeetingExplanation
  include ActiveModel::Model
  include Outropy::RichAttributes

  attribute :explanation, :string, "A description of what was discussed in detail, including the context surrounding the meeting"
  attr_accessor :explanation
end
