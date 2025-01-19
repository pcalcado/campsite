# frozen_string_literal: true

class MeetingCategorizer
  TASK_NAME = "categorize_meeting_task"
  CATEGORIES_DATA_SOURCE = "categorize_meeting_categories_data_source"
  CATEGORIES_INGESTION_TASK = "ingest_categorize_meeting_categories"

  def initialize
    @outropy = Outropy.client
    @categories_data_source_id = find_or_create_categories_data_source
    ingests_categories
    @classifier_task_id = find_or_create_classifier_task
  end

  def create_classifier_task
    possible_categories = Outropy::Types.one_of(MeetingCategory.pluck(:name))

    @outropy.create_classifier_task(
      name: TASK_NAME,
      prompt: "This is the transcript of a meeting. Classify the meeting into one of the following categories.",
      categories: @categories_data_source_id,
      input_type: CallRecording,
      output_type: possible_categories,
    )
  end

  def categorize_meeting(call_recording)
    Rails.logger.info("Classifying meeting for call_recording: #{call_recording.id}")

    task_result = @outropy.execute_task(
      task_id: @classifier_task_id,
      subject: call_recording,
    )

    raise "Task failed" if task_result.nil?

    name = Outropy::Types.the_choice(task_result)
    MeetingCategory.find_by!(name: name)
  end

  private

  def find_or_create_classifier_task
    @outropy.get_task_id(name: TASK_NAME) || create_classifier_task
  end

  def ingests_categories
    categories_task_id = @outropy.get_task_id(name: CATEGORIES_INGESTION_TASK)
    return if categories_task_id

    Rails.logger.info("Creating and executing task: #{CATEGORIES_INGESTION_TASK}")
    categories_task_id = create_ingestion_task
    ingest_all_categories(categories_task_id)
  end

  def find_or_create_categories_data_source
    data_source_id = @outropy.get_data_source_id(data_source_name: CATEGORIES_DATA_SOURCE)
    return data_source_id if data_source_id

    Rails.logger.info("Creating data source: #{CATEGORIES_DATA_SOURCE}")
    @outropy.create_data_source(
      name: CATEGORIES_DATA_SOURCE,
      description: "Data source for the categories of meetings",
    )
  end

  def create_ingestion_task
    @outropy.create_ingestion_task(
      name: CATEGORIES_INGESTION_TASK,
      prompt: "This is a possible category for meetings",
      input_type: MeetingCategory,
      destination_data_source: @categories_data_source_id,
    )
  end

  def ingest_all_categories(task_id)
    MeetingCategory.find_each do |category|
      Rails.logger.info("Ingesting category: #{category.name}")
      @outropy.execute_task(task_id: task_id, subject: category)
    end
    Rails.logger.info("Finished ingesting categories")
  end
end
