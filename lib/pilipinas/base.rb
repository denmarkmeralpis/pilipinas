# frozen_string_literal: true

module Pilipinas
  # Abstract base class for all Philippine geographic entities.
  #
  # Concrete subclasses ({Region}, {Province}, {City}, {Barangay}) must
  # implement {.data_file} to return the absolute path of their backing YAML
  # file.  Subclasses may also override {.build} to handle extra attributes.
  #
  # == Memory model
  #
  # YAML is parsed exactly once per class per process.  {Cache} stores three
  # structures for each entity type:
  #
  # * +:records+ — frozen Array of all instances in file order.
  # * +:by_code+ — frozen Hash keyed by down-cased code for O(1) look-ups.
  # * +:by_name+ — frozen Hash keyed by down-cased name for O(1) look-ups.
  #
  # Associated sub-collections (e.g. a Region's Provinces) are also cached so
  # repeated calls like +region.provinces+ are free after the first call.
  #
  # == Thread-safety
  #
  # All shared state is managed through {Cache}, which uses a +Mutex+ with
  # double-checked locking.  Entity objects are frozen value objects and are
  # therefore inherently thread-safe.
  #
  class Base
    # @return [String] geographic code (always a String, never nil)
    attr_reader :code

    # @return [String] human-readable name (always a String, never nil)
    attr_reader :name

    # Builds a frozen, immutable value object.
    #
    # @param code [String, Integer, #to_s] geographic code
    # @param name [String, #to_s]          human-readable name
    def initialize(code:, name:)
      @code = code.to_s.freeze
      @name = name.to_s.freeze
      freeze
    end

    # @return [String]
    def to_s
      "#{self.class.name.split('::').last}(code: #{@code}, name: #{@name})"
    end

    # @return [String]
    def inspect
      "#<#{self.class.name} code=#{@code.inspect} name=#{@name.inspect}>"
    end

    # Value equality based on class and code.
    #
    # @param other [Object]
    # @return [Boolean]
    def ==(other)
      other.is_a?(self.class) && other.code == @code
    end

    alias eql? ==

    # @return [Integer]
    def hash
      [self.class, @code].hash
    end

    # ─────────────────────────────────────────────────── class interface ──

    class << self
      # Returns every record for this entity type.
      #
      # The underlying YAML file is parsed at most once; subsequent calls
      # return the same frozen Array from {Cache}.
      #
      # @return [Array<Base>]
      def all
        index[:records]
      end

      # Total number of records.
      #
      # @return [Integer]
      def count
        index[:records].size
      end

      # First record in collection order.
      #
      # @return [Base, nil]
      def first
        index[:records].first
      end

      # Last record in collection order.
      #
      # @return [Base, nil]
      def last
        index[:records].last
      end

      # Find a single record by one attribute.
      #
      # Look-up is O(1) via a pre-built hash index and is case-insensitive.
      #
      # @example
      #   Pilipinas::Region.find_by(code: "17744")
      #   Pilipinas::Region.find_by(name: "REGION V (Bicol Region)")
      #
      # @param options [Hash{Symbol => String, Integer}]
      #   Exactly one key/value pair.  Supported keys: +:code+, +:name+.
      # @raise [ArgumentError]    if +options+ is empty
      # @raise [UnknownAttribute] if the key is not +:code+ or +:name+
      # @return [Base, nil]
      def find_by(options)
        raise ArgumentError, 'options hash must not be empty' if options.empty?

        attribute, value = options.first
        find_by_attribute(attribute.to_sym, value.to_s)
      end

      # Load an associated sub-collection from a per-code YAML file.
      #
      # Results are cached in {Cache}; repeated calls with the same arguments
      # are zero-cost after the first invocation.
      #
      # @param code [String, Integer] parent entity's code
      # @param dir  [Symbol, String]  sub-directory name under +data/+
      # @return [Array<Base>]
      def assoc_collection(code:, dir:)
        file = File.join(Pilipinas::DATA_DIR, dir.to_s, "#{code}.yml")
        Cache.fetch("assoc:#{name}:#{code}") do
          load_yaml(file).map { |h| build(h) }.freeze
        end
      end

      # Clear all cached data.
      #
      # Primarily useful between test examples to guarantee isolation.
      #
      # @return [void]
      def reset_cache
        Cache.clear
      end

      # @!method find_by_code(value)
      #   Find a record whose +code+ matches +value+ (case-insensitive).
      #   @param value [String, Integer]
      #   @return [Base, nil]

      # @!method find_by_name(value)
      #   Find a record whose +name+ matches +value+ (case-insensitive).
      #   @param value [String]
      #   @return [Base, nil]

      # Handles dynamic +find_by_<attribute>+ methods.
      #
      # @raise [UnknownAttribute] for any attribute other than +code+/+name+
      # @return [Base, nil]
      def method_missing(method_name, *args, **_kwargs, &)
        match = method_name.to_s.match(/\Afind_by_(.+)\z/)
        return super unless match

        attribute = match[1].to_sym
        raise UnknownAttribute, "Invalid attribute '#{attribute}'." \
          unless %i[code name].include?(attribute)

        find_by_attribute(attribute, args.first.to_s)
      end

      # @param method_name     [Symbol]
      # @param include_private [Boolean]
      # @return [Boolean]
      def respond_to_missing?(method_name, include_private = false)
        method_name.to_s.match?(/\Afind_by_(code|name)\z/) || super
      end

      private

      # Absolute path of the YAML file backing this class.
      # Subclasses *must* implement this method.
      #
      # @return [String]
      def data_file
        raise NotImplementedError, "#{self} must implement .data_file"
      end

      # Build a single entity instance from a raw YAML hash.
      # Subclasses may override to consume extra attributes.
      #
      # @param hash [Hash{Symbol => String}]
      # @return [Base]
      def build(hash)
        new(code: hash[:code], name: hash[:name])
      end

      # Return (or build and cache) the three-part look-up index.
      #
      # @return [Hash{Symbol => Object}]
      def index
        Cache.fetch("index:#{name}") { build_index }
      end

      # Parse the YAML file and build all three index structures.
      #
      # @return [Hash{Symbol => Object}]
      def build_index
        records = load_yaml(data_file).map { |h| build(h) }.freeze
        {
          records: records,
          by_code: records.to_h { |r| [r.code.downcase, r] }.freeze,
          by_name: records.to_h { |r| [r.name.downcase, r] }.freeze
        }.freeze
      end

      # Perform an O(1) look-up against the appropriate index.
      #
      # @param attribute [Symbol] +:code+ or +:name+
      # @param value     [String]
      # @raise [UnknownAttribute]
      # @return [Base, nil]
      def find_by_attribute(attribute, value)
        raise UnknownAttribute, "Invalid attribute '#{attribute}'." \
          unless %i[code name].include?(attribute)

        index[:"by_#{attribute}"][value.to_s.downcase]
      end

      # Parse a YAML file and return an Array of Hashes.
      #
      # Returns an empty Array when the file does not exist so that optional
      # per-entity association files are handled gracefully.
      #
      # @param file [String] absolute path
      # @return [Array<Hash>]
      def load_yaml(file)
        return [] unless File.exist?(file)

        Psych.load_file(file) || []
      end

      private :new
    end
  end
end
