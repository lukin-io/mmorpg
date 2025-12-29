# frozen_string_literal: true

# Load parallel_tests rake tasks for faster test execution
# See: https://github.com/grosser/parallel_tests
begin
  require "parallel_tests/tasks"
rescue LoadError
  # parallel_tests not available (production)
end
