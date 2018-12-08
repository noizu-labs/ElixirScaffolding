defmodule Noizu.Scaffolding.V2.ERPResolver do
  def id(o), do: o.__struct__.erp_handler().id(o)
  def ref(o), do: o.__struct__.erp_handler().ref(o)
  def sref(o), do: o.__struct__.erp_handler().sref(o)
  def entity(o, options \\ %{}), do: o.__struct__.erp_handler().entity(o, options)
  def entity!(o, options \\ %{}), do: o.__struct__.erp_handler().entity!(o, options)
  def record(o, options \\ %{}), do: o.__struct__.erp_handler().record(o, options)
  def record!(o, options \\ %{}), do: o.__struct__.erp_handler().record!(o, options)
end