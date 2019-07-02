module Pilipinas
  class Base
    attr_reader(
      :code,
      :name
    )

    def initialize(options = {})
      @code = options[:code]
      @name = options[:name]
    end

    class << self
      attr_accessor :data

      def assoc_collection(options)
        code = options.fetch(:code)
        dir = options.fetch(:dir)

        load_file(File.join(File.dirname(__FILE__), '..', 'data', dir.to_s, "#{code}.yml"))
      end

      def count
        all.count
      end

      def first
        all.first
      end

      def last
        all.last
      end

      def all
        load_data
      end

      def load_data
        raise 'Implement load_data'
      end

      def find_by(options)
        raise 'invalid hash' if options.empty?

        select_by(options.keys.first.to_s, options.values.first.to_s)
      end

      def method_missing(*args)
        regex = args.first.to_s.match(/^find_by_(.*)/)
        super if !regex || Regexp.last_match(1).nil?

        load_data unless data
        select_by(Regexp.last_match(1), args[1])
      end

      def load_file(file)
        reset_data
        yaml = YAML.load_file(file)
        yaml.each { |hash, _opts| add(new(hash)) } if yaml
        data
      end

      def add(region)
        self.data ||= []
        self.data << region
      end

      def select_by(attribute, val)
        attr, value = parse_attributes(attribute.downcase, (val ? val.to_s.downcase : val))

        obj = data.select { |c| c.send(attr.to_sym).downcase == value }
        validate(obj)
        obj.first
      end

      def parse_attributes(attr, val)
        raise Pilipinas::UnknownAttribute, "Invalid attribute '#{attr}'." unless %i[code name].include?(attr.to_sym)

        [attr, val]
      end

      def validate(obj)
        return nil if obj.empty?
      end

      def reset_data
        self.data = []
      end

      private :new
    end
  end
end
