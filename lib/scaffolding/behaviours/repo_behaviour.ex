#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.RepoBehaviour do
  alias Noizu.ElixirCore.CallingContext

  @type ref :: tuple
  @type opts :: Map.t

  @doc """
    Entity repo manages.
  """
  @callback entity() :: Map.t

  @doc """
    Compile time options.
  """
  @callback options() :: Module

  @doc """
    Match Records.
  """
  @callback match(any, CallingContext.t, opts) :: list

  @doc """
    Match Records. Transaction Wrapped
  """
  @callback match!(any, CallingContext.t, opts) :: list

  @doc """
    List Records.
  """
  @callback list(CallingContext.t, opts) :: list

  @doc """
    List Records. Transaction Wrapped
  """
  @callback list!(CallingContext.t, opts) :: list

  @doc """
    Fetch record.
  """
  @callback get(integer | atom, CallingContext.t, opts) :: any

  @doc """
    Fetch record. Transaction Wrapped
  """
  @callback get!(integer | atom, CallingContext.t, opts) :: any

  @doc """
    Update record.
  """
  @callback update(any, CallingContext.t, opts) :: any

  @doc """
    Update record. Transaction Wrapped
  """
  @callback update!(any, CallingContext.t, opts) :: any

  @doc """
    Delete record.
  """
  @callback delete(any, CallingContext.t, opts) :: boolean

  @doc """
    Delete record. Transaction Wrapped
  """
  @callback delete!(any, CallingContext.t, opts) :: boolean

  @doc """
    Create new record.
  """
  @callback create(any, CallingContext.t, opts) :: any

  @doc """
    Create new record. Transaction Wrapped
  """
  @callback create!(any, CallingContext.t, opts) :: any

  @doc """
    Hook for any post create steps.
    Provided an entity needs to setup linked objects.
  """
  @callback pre_create_callback(any, CallingContext.t, opts) :: any

  @doc """
    Hook for any post update steps.
  """
  @callback pre_update_callback(any, CallingContext.t, opts) :: any

  @doc """
    Hook for any post delete steps.
  """
  @callback pre_delete_callback(any, CallingContext.t, opts) :: any

  @doc """
    Hook for any post create steps.
    Provided an entity needs to setup linked objects.
  """
  @callback post_create_callback(any, CallingContext.t, opts) :: any


  @doc """
    Hook for any post get steps. (such as versioning)
  """
  @callback post_get_callback(any, CallingContext.t, opts) :: any

  @doc """
    Hook for any post update steps.
  """
  @callback post_update_callback(any, CallingContext.t, opts) :: any

  @doc """
    Hook for any post delete steps.
  """
  @callback post_delete_callback(any, CallingContext.t, opts) :: any

  @doc """
     generate new nmid.
  """
  @callback generate_identifier(any) :: integer | atom

  @doc """
     generate new nmid. Transaction Wrapped
  """
  @callback generate_identifier!(any) :: integer | atom

  @doc """
  Cast from json to struct.
  """
  @callback from_json(Map.t, CallingContext.t) :: any

  @methods ([
    :entity, :options, :generate_identifier!, :generate_identifier,
    :update, :update!, :delete, :delete!, :create, :create!, :get, :get!,
    :match, :match!, :list, :list!, :post_get_callback, :pre_create_callback, :pre_update_callback, :pre_delete_callback,
    :post_create_callback, :post_get_callback, :post_update_callback, :post_delete_callback,
    :from_json, :extract_date])

  defmacro __using__(options) do
    # Only include implementation for these methods.
    option_arg = Keyword.get(options, :only, @methods)
    only = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Don't include implementation for these methods.
    option_arg = Keyword.get(options, :override, [])
    override = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Final set of methods to provide implementations for.
    required? = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, only[method] && !override[method]) end)

    # Implementation for Persistance layer interactions.
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Scaffolding.RepoBehaviour.AmnesiaProvider)

    # Auditing details
    audit_engine = Keyword.get(options, :audit_engine, Application.get_env(:noizu_scaffolding, :default_audit_engine, Noizu.Scaffolding.AuditEngine.Default))

    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @behaviour Noizu.Scaffolding.RepoBehaviour
      @implementation (unquote(implementation_provider))
      use unquote(implementation_provider), unquote(options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def audit_engine, do: unquote(audit_engine)
      #-------------------------------------------------------------------------
      # from_json
      #-------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      if unquote(required?.from_json) do
        def from_json(_json, _context) do
          throw "From Json Not Implemented For #{__MODULE__}.  use override: from_json and provide your implementation."
        end # end from_json/2
      end

    end # end quote
  end # end defmacro __using__(options)
end # end defmodule Noizu.Scaffolding.RepoBehaviour
