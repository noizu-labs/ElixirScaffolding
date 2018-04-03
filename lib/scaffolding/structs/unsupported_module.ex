#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.UnsupportedModule do
  @type t :: %__MODULE__{
    reference: any,
  }

  defstruct [
    reference: nil,
  ]

  @behaviour Noizu.Scaffolding.EntityBehaviour

  def id(item), do: raise "UnsupportedModule #{inspect item}"
  def ref(item), do: raise "UnsupportedModule #{inspect item}"
  def sref(item), do: raise "UnsupportedModule #{inspect item}"
  def entity(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def entity!(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def record(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def record!(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def as_record(item, _options), do: raise "UnsupportedModule #{inspect item}"
  def sref_module(), do: "unsupported-module"
  def has_permission(_,_,_,_), do: false
  def has_permission!(_,_,_,_), do: false
  def compress(entity), do: entity
  def compress(entity, _options), do: entity
  def expand(entity), do: entity
  def expand(entity, _options), do: entity
  def from_json(json, _options), do: raise "UnsupportedModule #{inspect json}"
  def repo(), do: __MODULE__
end

defimpl Noizu.ERP, for: Noizu.Scaffolding.UnsupportedModule do
  def id(_item), do: raise "UnsupportedModule"
  def ref(_item), do: raise "UnsupportedModule"
  def sref(_item), do: raise "UnsupportedModule"
  def entity(_item, _options \\ nil), do: raise "UnsupportedModule"
  def entity!(_item, _options \\ nil), do: raise "UnsupportedModule"
  def record(_item, _options \\ nil), do: raise "UnsupportedModule"
  def record!(_item, _options \\ nil), do: raise "UnsupportedModule"
end
