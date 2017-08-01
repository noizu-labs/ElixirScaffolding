defmodule Noizu.Scaffolding.UnsupportedModule do
  @type t :: %__MODULE__{
    reference: any,
  }

  defstruct [
    reference: nil,
  ]

  @behaviour Noizu.Scaffolding.EntityBehaviour
  def ref(item), do: raise "UnsupportedModule #{inspect item}"
  def sref(item), do: raise "UnsupportedModule #{inspect item}"
  def entity(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def entity!(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def record(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def record!(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def as_record(item), do: raise "UnsupportedModule #{inspect item}"
  def sref_module(), do: "unsupported-module"
end

defimpl Noizu.ERP, for: Noizu.Scaffolding.UnsupportedModule do
  def ref(_item), do: raise "UnsupportedModule"
  def sref(_item), do: raise "UnsupportedModule"
  def entity(_item, _options \\ nil), do: raise "UnsupportedModule"
  def entity!(_item, _options \\ nil), do: raise "UnsupportedModule"
  def record(_item, _options \\ nil), do: raise "UnsupportedModule"
  def record!(_item, _options \\ nil), do: raise "UnsupportedModule"
end
