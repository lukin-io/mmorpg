# frozen_string_literal: true

module Manage
  # Applies bounded, dependency-free pagination to a management relation.
  class PaginatedRelation
    DEFAULT_PER_PAGE = 50
    MAX_PER_PAGE = 100

    Result = Data.define(:records, :page, :per_page, :total_count) do
      def total_pages
        [(total_count.to_f / per_page).ceil, 1].max
      end

      def previous_page
        page - 1 if page > 1
      end

      def next_page
        page + 1 if page < total_pages
      end
    end

    def initialize(relation:, page:, per_page: DEFAULT_PER_PAGE)
      @relation = relation
      @page = [Integer(page, exception: false) || 1, 1].max
      @per_page = (Integer(per_page, exception: false) || DEFAULT_PER_PAGE).clamp(1, MAX_PER_PAGE)
    end

    def call
      Result.new(
        records: relation.offset((page - 1) * per_page).limit(per_page),
        page:,
        per_page:,
        total_count: relation.count
      )
    end

    private

    attr_reader :relation, :page, :per_page
  end
end
