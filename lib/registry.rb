require "timed_cache"

module Registry
  class BaseRegistry
    CACHE_LIFETIME = 300 # 5 minutes

    def initialize(index, field_definitions, format, fields = %w{slug link title}, clock = Time)
      @cache = TimedCache.new(self.class::CACHE_LIFETIME, clock) { fetch }

      @field_definitions = fields.reduce({}) { |result, field|
        result[field] = field_definitions[field]
        result
      }

      @format = format
      @index = index
    end

    def all
      @cache.get
    end

    def [](slug)
      all.find { |o| o['slug'] == slug }
    end

  private
    def fetch
      find_documents_by_format.to_a
    end

    def find_documents_by_format
      @index.documents_by_format(@format, @field_definitions)
    end
  end
end
