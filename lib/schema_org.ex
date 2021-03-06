defmodule SchemaOrg do
  alias SchemaOrg.Schema

  def create_schema(type) do
    %Schema{type: type}
  end

  def create_schema(type, %{} = properties) do
    %Schema{type: type, properties: properties}
  end

  def set_property(schema, key, value) do
    %{schema | properties: Map.put(schema.properties, key, value)}
  end

  def to_map(%Schema{context: context}) when context == nil do
    {:error, "No context specified"}
  end

  def to_map(%Schema{type: type}) when type == nil do
    {:error, "No type specified"}
  end

  def to_map(%Schema{} = schema) do
    meta = %{"@context" => schema.context, "@type" => schema.type}
    
    properties = for {key, value} <- schema.properties, into: %{} do
      case {key, value} do
        {key, %Schema{} = value} -> 
          {:ok, map} = to_map(value)
          map = Map.drop(map, ["@context"])
          {key, map}
        {key, value} ->
          {key, value}
      end
    end
    
    {:ok, Map.merge(meta, properties)}
  end

  def to_json(%Schema{} = schema) do
    case to_map(schema) do
      {:ok, map} -> Poison.encode(map);
      {:error, reason} -> {:error, reason}
    end
  end

  def to_script(%Schema{} = schema) do
    case to_json(schema) do
      {:ok, json} -> {:ok, wrap_in_script_tag(json)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp wrap_in_script_tag(string) do
    ~s(<script type="application/ld+json">) <> string <> ~s(</script>)
  end
end
