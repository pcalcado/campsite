# frozen_string_literal: true
require 'ai/meeting_explanation'
class MeetingExplainer
  def initialize
    @outropy = Outropy.client
    @task_ids_per_category = find_or_create_task_ids
  end

  # @param [MeetingCategory] category the category of the meeting
  # @param [CallRecording] call_recording the recording of the meeting
  # @return [MeetingExplanation]
  def explain(category, call_recording)
    task_id = @task_ids_per_category[category.name] || raise("No task found for category: [#{category.name}] among #{@task_ids_per_category.keys}")
    result = @outropy.execute_task(
      task_id: task_id,
      subject: call_recording,
    )
    MeetingExplanation.new(result)
  end

  private

  # @param [MeetingCategory] category the category of the meeting
  def find_or_create_task_ids
    MeetingCategory.find_each.with_object({}) do |category, task_ids|
      task_ids[category.name] = find_or_create_task(category)
    end
  end

  def find_or_create_task(category)
    @outropy.get_task_id(name: task_name_for(category)) || create_task(category)
  end

  def create_task(category)
    @outropy.create_explainer_task(
      name: task_name_for(category),
      prompt: <<~EOM,
        This is the transcript of a meeting. Create a document that explains in detail both what was discussed and the context surrounding the meeting so that people who were not present can understand.
      EOM
      guidelines: category.explanation_guidelines,
      input_type: CallRecording,
      output_type: MeetingExplanation,
      reference_data: category.data_sources_to_use,
    )
  end

  def task_name_for(category)
    "explain_#{category.name}_task"
  end
end