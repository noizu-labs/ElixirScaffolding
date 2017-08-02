defmodule Noizu.Scaffolding.InternalTask do
  @type t :: %__MODULE__{}
  defstruct []

  @behaviour Noizu.Scaffolding.EntityBehaviour
  def ref(item), do: {:ref, __MODULE__, :task}
  def sref(item), do: "ref.internal.task"
  def entity(item, _options), do: %Noizu.Scaffolding.InternalTask{}
  def entity!(item, _options), do: %Noizu.Scaffolding.InternalTask{}
  def record(item, _options), do: %Noizu.Scaffolding.InternalTask{}
  def record!(item, _options), do: %Noizu.Scaffolding.InternalTask{}
  def as_record(item), do: %Noizu.Scaffolding.InternalTask{}
  def sref_module(), do: "internal"
end

defimpl Noizu.ERP, for: Noizu.Scaffolding.InternalTask do
  def ref(item), do: Noizu.Scaffolding.EntityBehaviour.ref(item)
  def sref(item), do: Noizu.Scaffolding.EntityBehaviour.sref(item)
  def entity(item, options \\ nil), do: Noizu.Scaffolding.EntityBehaviour.entity(item, options)
  def entity!(item, options \\ nil), do: Noizu.Scaffolding.EntityBehaviour.entity(item, options)
  def record(item, options \\ nil), do: Noizu.Scaffolding.EntityBehaviour.record(item, options)
  def record!(item, options \\ nil), do: Noizu.Scaffolding.EntityBehaviour.record!(item, options)
end
