# frozen_string_literal: true

class MeetingSummarizer
  def initialize
    @outropy = Outropy.client
    @task_ids_per_category = find_or_create_task_ids
  end

  # @param [MeetingCategory] category the category of the meeting
  # @param [MeetingExplanation] explanation the explanation of the meeting
  # @return [MeetingSummary]
  def summarize(category, explanation)
    task_id = @task_ids_per_category[category.name] || raise("No task found for category: [#{category.name}] among #{@task_ids_per_category.keys}")
    result = @outropy.execute_task(
      task_id: task_id,
      subject: explanation,
    )
    MeetingSummary.new(result)
  end

  private

  # @param [MeetingCategory] category the category of the meeting
  def find_or_create_task_ids
    MeetingCategory.find_each.with_object({}) do |category, task_ids|
      task_ids[category.name] = find_or_create_task(category)
    end
  end

  def find_or_create_task(category)
    @outropy.get_task_id(name: summary_task_name_for(category)) || create_task(category)
  end

  def create_task(category)
    @outropy.create_contextualizer_task(
      name: summary_task_name_for(category),
      prompt: <<~EOM,
        This is the detailed explanation of a meeting. Contextualize the meeting so that people who were not present can understand.
      EOM
      guidelines: category.summarization_guidelines,
      input_type: MeetingExplanation,
      output_type: MeetingSummary,
      reference_data: category.data_sources_to_use,
    )
  end

  def summary_task_name_for(category)
    "summarize_#{category.name}_task"
  end
end
