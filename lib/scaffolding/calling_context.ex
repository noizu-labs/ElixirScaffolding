#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc.. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.CallingContext do
  alias Noizu.Scaffolding.CallingContext
  @vsn 0.01

  @type t :: %CallingContext{
    caller: tuple,
    token: String.t,
    reason: String.t,
    auth: Any,
    options: Map.t,
    vsn: float
  }

  defstruct [
    caller: nil,
    token: nil,
    reason: nil,
    auth: nil,
    options: nil,
    vsn: @vsn
  ]

  def generate_token do
    UUID.uuid4(:hex)
  end # end generate_token/0

  def internal do
    %__MODULE__{
      caller: Noizu.Scaffolding.InternalTask.ref(:internal),
      auth: Noizu.Scaffolding.InternalTask.ref(:internal)
    }
  end
end # end defmodule Noizu.Scaffolding.CallingContext
