# frozen_string_literal: true

require "outropy"

class MeetingCategory
  include ActiveModel::Model
  include Outropy::RichAttributes

  attribute :id, :integer, "The ID of the category"
  attribute :name, :string, "The name of the category"
  attribute :description, :string, "The description of the category"
  attribute :explanation_guidelines, :string, "The explanation guidelines for the category"
  attribute :summarization_guidelines, :string, "The summarization guidelines for the category"
  attribute :data_sources_to_use, :array, "The data sources to use for the category"

  attr_accessor :id, :name, :description, :explanation_guidelines,
                :summarization_guidelines, :data_sources_to_use

  def self.pluck(*columns)
    all.map do |record|
      if columns.size == 1
        record.public_send(columns.first)
      else
        columns.map { |column| record.public_send(column) }
      end
    end
  end

  def self.find_each(batch_size: 1000, start: nil, finish: nil, &block)
    return enum_for(:find_each) unless block_given?

    records = all
    records = records.select { |r| r.id >= start } if start
    records = records.select { |r| r.id <= finish } if finish

    records.each(&block)
  end

  def self.all
    [
      MeetingCategory.new(
        id: 1,
        name: "Daily standup",
        description: "A daily meeting where the team members discuss their progress and plans for the day",
        explanation_guidelines: <<~EOM,
          This meeting is extremely time-sensitive and happens every day, so it's incremental information. In the explanation, make sure to add context from projects and discussions that were referenced in the meeting so that someone reading this at a later date can understand the context.
        EOM
        summarization_guidelines: <<~EOM,
          For each person, report on what they did yesterday, what they plan to do today, and any blockers they have 
        EOM
        data_sources_to_use: [Note, Project, User, Message, Post],
      ),
      MeetingCategory.new(
        id: 2,
        name: "Technical discussion",
        description: "A meeting focused on discussing technical issues and solutions",
        explanation_guidelines: <<~EOM,
          This meeting is focused on discussing technical issues and solutions. It is important to capture the context for the discussion at this particular point in time and pay extra attention to alternatives discussed and why they were chosen or rejected.
        EOM
        summarization_guidelines: <<~EOM,
          Explain the question being discussed in one sentence, then list the options considered with a brief explanation of why each was chosen or rejected. Use the last paragraph to summarize the final decision.
        EOM
        data_sources_to_use: [Note, Project, User, Message, Post],
      ),
      MeetingCategory.new(
        id: 3,
        name: "Casual chat",
        description: "A casual meeting where team members discuss non-work-related topics",
        explanation_guidelines: <<~EOM,
          This meeting is a casual chat where team members discuss non-work-related topics. The explanation should capture the mood and tone of the meeting, as well as any topics that were discussed. 
        EOM
        summarization_guidelines: <<~EOM,
          Summarize the tone and mood and a bullet point list of the topics discussed
        EOM
        data_sources_to_use: [Message, Post, Comment, User],
      ),
      MeetingCategory.new(
        id: 4,
        name: "Stakeholder meeting",
        description: "A meeting with stakeholders to discuss project progress and issues",
        explanation_guidelines: <<~EOM,
          The most important aspect of this meeting is what was shared with the stakeholders, what was their feedback, and what decisions were made. The explanation should capture the key points discussed and any decisions made. Make sure to explain the context of anything mentioned in the meeting.
        EOM
        summarization_guidelines: <<~EOM,
          Write a summary in three sentences: what was shared with the stakeholders, what was their feedback, and what decisions were made.
        EOM
        data_sources_to_use: [Note, Project, User, Message, Post],
      ),
    ]
  end

  def self.find_by!(criteria = {})
    result = find_by(criteria)
    raise RecordNotFound, "Couldn't find #{name} with #{criteria.inspect}" if result.nil?
    result
  end

  def self.find_by(criteria = {})
    all.find do |item|
      criteria.all? { |key, value| item.respond_to?(key) && item.public_send(key) == value }
    end
  end
end