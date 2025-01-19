# frozen_string_literal: true

class AgendaItems
  include ActiveModel::Model
  include Outropy::RichAttributes

  attribute :title, :string, "A descriptive title for the agenda item"

  attr_accessor :title
end

class ActionItem
  include ActiveModel::Model
  include Outropy::RichAttributes

  attribute :title, :string, "A descriptive title for the action item"
  attribute :assigned_to, :string, "The person responsible for the action item"
  attribute :due_date, :due_date, "The date by which the action item should be completed"

  attr_accessor :title, :assigned_to, :due_date
end

class MeetingSummary
  include ActiveModel::Model
  include Outropy::RichAttributes

  attribute :title, :string, "A descriptive title for the meeting"
  attribute :summary, :string, "A summary of the meeting"
  attribute :agenda, [AgendaItems], "The items on the meeting agenda"
  attribute :action_items, [ActionItem], "The action items resulting from the meeting"
  attr_accessor :title, :summary, :agenda, :action_items
end
