require "registry"

class Registries < Struct.new(:search_server, :search_config)
  def [](name)
    as_hash[name]
  end

  def as_hash
    @registries ||= {
      organisations: organisations,
      specialist_sectors: specialist_sectors,
      topics: registry_for_document_format('topic'),
      document_series: registry_for_document_format('document_series'),
      document_collections: registry_for_document_format('document_collection'),
      world_locations: registry_for_document_format('world_location'),
      people: registry_for_document_format('person'),
    }
  end

private

  def organisations
    Registry::BaseRegistry.new(
      index,
      field_definitions,
      "organisation",
      %w{slug link title acronym organisation_type organisation_state}
    )
  end

  def specialist_sectors
    Registry::BaseRegistry.new(
      search_server.index_for_search(settings.search_config.content_index_names),
      field_definitions,
      "specialist_sector"
    )
  end

  def registry_for_document_format(format)
    Registry::BaseRegistry.new(index, field_definitions, format)
  end

  def index
    search_server.index_for_search([settings.search_config.registry_index])
  end

  def field_definitions
    @field_definitions ||= search_server.schema.field_definitions
  end
end
