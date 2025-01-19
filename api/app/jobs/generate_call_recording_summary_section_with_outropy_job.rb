# frozen_string_literal: true

require "ai/meeting_category"
require "ai/meeting_categorizer"
require "ai/meeting_explainer"
require "ai/meeting_summarizer"
require "ai/meeting_explanation"
require "ai/meeting_summary"

class GenerateCallRecordingSummarySectionWithOutropyJob < BaseJob
  sidekiq_options queue: "background", retry: 5

  def perform(call_recording_id)
    call_recording = CallRecording.find(call_recording_id)

    meeting_categorizer = MeetingCategorizer.new
    meeting_category = meeting_categorizer.categorize_meeting(call_recording)

    explainer = MeetingExplainer.new
    # Ideally, we would save the explanation because it includes a snapshot of all context needed to generate further artifacts
    explanation = explainer.explain(meeting_category, call_recording)

    summarizer = MeetingSummarizer.new
    summary = summarizer.summarize(meeting_category, explanation)

    summary_section = call_recording.summary_sections.find_by(section: :summary)
    summary_section.update!(response: summary.summary, status: :success)
    maybe_trigger_finished(summary_section)

    agenda_section = call_recording.summary_sections.find_by(section: :agenda)
    agenda_section.update!(response: summary.agenda, status: :success)
    maybe_trigger_finished(agenda_section)

    action_items_section = call_recording.summary_sections.find_by(section: :next_steps)
    action_items_section.update!(response: summary.action_items, status: :success)
    maybe_trigger_finished(action_items_section)

  end

  private

  def maybe_trigger_finished(section)
    if section.call_recording.summary_sections.all?(&:success?)
      call = section.call_recording.call
      call.update_summary_from_recordings! if call.summary.blank?
      call.trigger_stale
      call.reindex(mode: :async)
    end
  end
end
