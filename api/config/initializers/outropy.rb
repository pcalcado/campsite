# frozen_string_literal: true
require 'outropy'

Rails.application.config.to_prepare do
  Outropy.configuration = {
    api_key: "phil@outropy.ai"
  }
end