defprotocol Noizu.RestrictedProtocol do
  @fallback_to_any true
  def restricted_view(entity, context, options \\ nil)
  def restricted_update(entity, current, context, options \\ nil)
  def restricted_create(entity, context, options \\ nil)
end


# Default unlimited access.
#defimpl Noizu.RestrictedProtocol, for: Any do
#  def restricted_view(%{__struct__: kind} = entity, _context, _options), do: put_in(Map.from_struct(entity), [:kind], kind)
#  def restricted_view(entity, _context, _options), do: entity
#  def restricted_edit(entity, _current, _context, _options), do: entity
#  def restricted_create(entity, _context, _options), do: entity
#end
