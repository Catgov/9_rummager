require "json"
require "yaml"
require "schema/document_types"
require "schema/field_definitions"
require "schema/index_schema"
require "schema/synonyms"

class SchemaConfig
  attr_reader :field_definitions

  def initialize(config_path)
    @config_path = config_path
    @field_definitions = FieldDefinitionParser.new(config_path).parse
    @document_types = DocumentTypesParser.new(config_path, @field_definitions).parse
    @index_schemas = IndexSchemaParser.parse_all(config_path, @document_types)
    @index_synonyms, @search_synonyms = SynonymParser.new(config_path).parse
  end

  def schema_for_alias_name(alias_name)
    @index_schemas.each do |index_name, schema|
      if alias_name.start_with?(index_name)
        return schema
      end
    end
    raise RuntimeError("No schema found for alias `#{alias_name}")
  end

  def elasticsearch_settings(index_name)
    @settings ||= elasticsearch_index["settings"]
  end

  def document_types(index_name)
    index_name = index_name.sub(/[-_]test$/, '')
    @index_schemas.fetch(index_name).document_types
  end

  def elasticsearch_mappings(index_name)
    index_name = index_name.sub(/[-_]test$/, '')
    @index_schemas.fetch(index_name).es_mappings
  end

private
  attr_reader :config_path

  def schema_yaml
    load_yaml("elasticsearch_schema.yml")
  end

  def elasticsearch_index
    schema_yaml["index"].tap do |index|
      index["settings"]["analysis"]["filter"].merge!(
        "old_synonym" => old_synonym_filter,
        "stemmer_override" => stems_filter,
        "index_synonym" => @index_synonyms.es_config,
        "search_synonym" => @search_synonyms.es_config,
        "synonym_protwords" => @index_synonyms.protwords_config,
      )
    end
  end

  def old_synonym_filter
    load_yaml("old_synonyms.yml")
  end

  def stems_filter
    load_yaml("stems.yml")
  end

  def load_yaml(file_path)
    YAML.load_file(File.join(config_path, file_path))
  end
end