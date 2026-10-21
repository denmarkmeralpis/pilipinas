# frozen_string_literal: true

module Pilipinas
  # Separate PHLPost postal labels. No inferred PSGC joins or barangay coverage.
  module Postal
    Entry = Data.define(:region, :province, :locality, :zip_code)
    Result = Data.define(:status, :candidates, :rejected_rows) do
      def zip_codes = candidates.map(&:zip_code).uniq.freeze
      def suggestion = status == :matched ? candidates.first.zip_code : nil
    end
    MISSING = Result.new(status: :missing, candidates: [].freeze, rejected_rows: [].freeze)
    private_constant :MISSING

    def self.metadata = Pilipinas.metadata.fetch('postal')

    # Case/whitespace-insensitive exact postal labels. No fuzzy matching.
    # Omit province to see all candidates for a repeated locality name.
    def self.lookup(locality:, province: nil, region: nil)
      query = normalized_query(locality, province, region)
      return MISSING if query.values.any?(&:empty?)

      data = index
      matches = matching_entries(data[:valid].fetch(query[:locality], []), query)
      rejected = matching_rejections(data[:rejected], query)
      status = { 0 => :missing, 1 => :matched }.fetch(matches.size, :ambiguous)
      Result.new(status: status, candidates: matches, rejected_rows: rejected)
    end

    def self.normalized_query(locality, province, region)
      { locality: locality, province: province, region: region }
        .reject { |key, value| key != :locality && value.nil? }.transform_values { |value| normalize(value) }
    end
    private_class_method :normalized_query

    def self.matching_entries(entries, query)
      entries.select do |row|
        query.all? { |key, value| normalize(row.public_send(key)) == value }
      end.freeze
    end
    private_class_method :matching_entries

    def self.matching_rejections(rows, query)
      rows.select do |row|
        query.all? { |key, value| normalize(row.fetch(key.to_s)) == value }
      end.freeze
    end
    private_class_method :matching_rejections

    def self.normalize(value) = value.to_s.strip.downcase.gsub(/\s+/, ' ')
    private_class_method :normalize

    def self.index
      Cache.fetch('postal') do
        rows = JSON.parse(File.read(File.join(DATA_DIR, 'postal.json')), symbolize_names: true, freeze: true)
        valid = entry_index(rows)
        rejected = JSON.parse(File.read(File.join(DATA_DIR, 'postal_rejections.json')), freeze: true)
        { valid: valid, rejected: rejected }.freeze
      end
    end
    private_class_method :index

    def self.entry_index(rows)
      entries = rows.uniq.map { |row| Entry.new(**row) }
      entries.group_by { |entry| normalize(entry.locality) }.transform_values(&:freeze).freeze
    end
    private_class_method :entry_index
  end
end
