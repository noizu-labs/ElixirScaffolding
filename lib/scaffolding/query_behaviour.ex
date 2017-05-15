#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.QueryBehaviour do
  @type ref :: tuple
  @type opts :: Map.t

  @callback list(Noizu.Scaffolding.CallingContext.t, opts) :: list | {:error, any}
  @callback get(any, Noizu.Scaffolding.CallingContext.t, opts) :: any | {:error, any}
  @callback delete(any, Noizu.Scaffolding.CallingContext.t, opts) :: :ok | {:error, any}
  @callback update(any, Noizu.Scaffolding.CallingContext.t, opts) :: any | {:error, any}
  @callback delete(any, Noizu.Scaffolding.CallingContext.t, opts) :: any | {:error, any}
end
