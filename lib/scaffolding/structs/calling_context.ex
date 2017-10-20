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
    time: DateTime.t | nil,
    outer_context: CalingContext.t,
    vsn: float
  }

  defstruct [
    caller: nil,
    token: nil,
    reason: nil,
    auth: nil,
    options: nil,
    time: nil,
    outer_context: nil,
    vsn: @vsn
  ]

  @default_reason(:not_specified)

  def generate_token do
    UUID.uuid4(:hex)
  end # end generate_token/0

  def get_token(%Plug.Conn{} = conn, default \\ :generate) do
    conn.body_params["request-id"] || case (Plug.Conn.get_resp_header(conn, "x-request-id")) do
      [] -> default || generate_token()
      [h|_t] -> h
    end
  end

  def get_reason(%Plug.Conn{} = conn, default \\ nil) do
    conn.body_params["call-reason"] || case (Plug.Conn.get_resp_header(conn, "x-call-reason")) do
      [] -> default || nil
      [h|_t] -> h
    end
  end

  #-----------------------------------------------------------------------------
  # Helper CallingContext
  #-----------------------------------------------------------------------------
  def new(caller) do
    new(caller, caller, :generate, %{})
  end

  def new(caller, auth) do
    new(caller, auth, :generate, %{})
  end

  def new(caller, auth, token) do
    new(caller, auth, token, %{})
  end

  def new(caller, auth, token, %{} = options) do
    time = options[:time] || DateTime.utc_now()
    token = if (token == :generate), do: generate_token(), else: token
    reason = options[:reason] || @default_reason
    outer_context = options[:outer_context]
    %__MODULE__{caller: caller, auth: auth, time: time, outer_context: outer_context, token: token, reason: reason}
  end

  #-----------------------------------------------------------------------------
  # Internal CallingContext
  #-----------------------------------------------------------------------------
  def internal(), do: Noizu.Scaffolding.InternalTask.calling_context(:internal)
  def internal(env, opts \\ %{})
  def internal(env, opts), do: Noizu.Scaffolding.InternalTask.calling_context(:internal, env, opts)

  #-----------------------------------------------------------------------------
  # System CallingContext
  #-----------------------------------------------------------------------------
  def system(), do: Noizu.Scaffolding.InternalTask.calling_context(:system)
  def system(env, opts \\ %{})
  def system(env, opts), do: Noizu.Scaffolding.InternalTask.calling_context(:system, env, opts)

  #-----------------------------------------------------------------------------
  # Restricted CallingContext
  #-----------------------------------------------------------------------------
  def restricted(), do: Noizu.Scaffolding.InternalTask.calling_context(:restricted)
  def restricted(env, opts \\ %{})
  def restricted(env, opts), do: Noizu.Scaffolding.InternalTask.calling_context(:restricted, env, opts)
end # end defmodule Noizu.Scaffolding.CallingContext


if Application.get_env(:noizu_scaffolding, :inspect_calling_context, true) do
  #-----------------------------------------------------------------------------
  # Inspect Protocol
  #-----------------------------------------------------------------------------
  defimpl Inspect, for: Noizu.Scaffolding.CallingContext do
    import Inspect.Algebra
    def inspect(entity, opts) do
      heading = "#CallingContext(#{entity.token})"
      {seperator, end_seperator} = if opts.pretty, do: {"\n   ", "\n"}, else: {" ", " "}
      inner = cond do
        opts.limit == :infinity ->
          concat(["<#{seperator}", to_doc(Map.from_struct(entity), opts), "#{seperator}>"])
        opts.limit >= 200 ->
          concat ["<",
          "#{seperator}caller: #{inspect entity.caller},",
          "#{seperator}reason: #{inspect entity.reason},",
          "#{seperator}permissions: #{inspect entity.auth[:permissions]}",
          "#{end_seperator}>"]
        opts.limit >= 150 ->
          concat ["<",
          "#{seperator}caller: #{inspect entity.caller},",
          "#{seperator}reason: #{inspect entity.reason}",
          "#{end_seperator}>"]
        opts.limit >= 100 ->
          concat ["<",
          "#{seperator}caller: #{inspect entity.caller}",
          "#{end_seperator}>"]
        true -> "<>"
      end
      concat [heading, inner]
    end # end inspect/2
  end # end defimpl
end
