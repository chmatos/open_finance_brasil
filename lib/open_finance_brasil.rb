# frozen_string_literal: true

require_relative "open_finance_brasil/version"

require "net/http"
require "json"
require "open_finance_brasil/version"
require "open_finance_brasil/client"

module OpenFinanceBrasil
  class Error < StandardError; end
  # Your code goes here...
end