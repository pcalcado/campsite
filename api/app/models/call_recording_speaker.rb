# frozen_string_literal: true

class CallRecordingSpeaker < ApplicationRecord
  include Outropy::AutoIngest
  belongs_to :call_recording
  belongs_to :call_peer
end
