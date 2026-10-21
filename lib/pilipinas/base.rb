# frozen_string_literal: true

module Pilipinas
  # Immutable local PSGC record. Codes are official ten-digit strings.
  class Base
    ATTRIBUTES = %i[code name level correspondence_code parent_code region_code province_code
                    city_code submunicipality_code area_code psgc_province_code city_class source_name note].freeze
    INDEXED = %i[code name correspondence_code parent_code region_code province_code city_code
                 submunicipality_code area_code].freeze
    EMPTY = [].freeze
    private_constant :INDEXED, :EMPTY

    attr_reader(*ATTRIBUTES)

    def initialize(**attributes)
      attributes.each do |key, value|
        raise UnknownAttribute, "Invalid attribute '#{key}'." unless ATTRIBUTES.include?(key)

        instance_variable_set("@#{key}", value.to_s.freeze)
      end
      freeze
    end

    def to_s = "#{self.class.name.split('::').last}(code: #{code}, name: #{name})"
    def inspect = "#<#{self.class.name} code=#{code.inspect} name=#{name.inspect}>"
    def ==(other) = other.is_a?(self.class) && other.code == code
    alias eql? ==
    def hash = [self.class, code].hash

    def region = Region.find_by_code(region_code)
    def province = Province.find_by_code(province_code)
    def city = City.find_by_code(city_code)
    def area = Area.find_by_code(area_code)
    def submunicipality = Submunicipality.find_by_code(submunicipality_code)
    def parent = Pilipinas.find_by_code(parent_code)

    class << self
      def all = index[:records]
      def count = all.size
      def first = all.first
      def last = all.last

      # All matching records, including repeated names. Filters can be combined.
      def where(options = {})
        normalized = normalize_options(options)
        candidates = normalized.filter_map { |key, value| index[key]&.fetch(value, EMPTY) }.min_by(&:size) || all
        candidates.select { |r| matches?(r, normalized) }.freeze
      end

      # Never silently choose one of several identically named places.
      def find_by(options)
        raise ArgumentError, 'options hash must not be empty' if options.empty?

        matches = where(options)
        if matches.size > 1
          raise AmbiguousMatch,
                "#{self}: #{matches.size} matches for #{options.inspect}; use .where or include parent codes"
        end

        matches.first
      end

      # Compatibility with the old association entry point, without per-parent files.
      def assoc_collection(code:, dir:)
        attribute = { 'regions' => :region_code, 'provinces' => :province_code, 'cities' => :city_code }[dir.to_s]
        attribute ? where(attribute => code) : EMPTY
      end

      def reset_cache = Cache.clear

      def method_missing(method_name, *args, **_kwargs, &)
        match = method_name.to_s.match(/\Afind_by_(.+)\z/)
        return super unless match

        find_by(match[1].to_sym => args.first)
      end

      def respond_to_missing?(method_name, include_private = false)
        match = method_name.to_s.match(/\Afind_by_(.+)\z/)
        (match && ATTRIBUTES.include?(match[1].to_sym)) || super
      end

      private

      def normalize_options(options)
        options.to_h do |key, value|
          key = key.to_sym
          raise UnknownAttribute, "Invalid attribute '#{key}'." unless ATTRIBUTES.include?(key)

          [key, value&.to_s&.downcase]
        end
      end

      def matches?(record, options)
        options.all? { |key, value| record.public_send(key)&.downcase == value }
      end

      def data_file
        raise NotImplementedError, "#{self} must implement .data_file"
      end

      def index
        Cache.fetch("index:#{name}") do
          records = JSON.parse(File.read(data_file), symbolize_names: true, freeze: true)
                        .map { |row| new(**row) }.freeze
          attribute_indexes(records).merge(records: records).freeze
        end
      end

      def attribute_indexes(records)
        INDEXED.to_h do |attribute|
          groups = records.group_by { |r| r.public_send(attribute)&.downcase }
          [attribute, groups.transform_values(&:freeze).freeze]
        end
      end

      private :new
    end
  end
end
