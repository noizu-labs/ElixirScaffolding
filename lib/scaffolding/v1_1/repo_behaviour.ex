#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V1_1.RepoBehaviour do
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

#  @methods ([
#    :entity, :options, :generate_identifier!, :generate_identifier,
#    :update, :update!, :delete, :delete!, :create, :create!, :get, :get!,
#    :match, :match!, :list, :list!, :post_get_callback, :pre_create_callback, :pre_update_callback, :pre_delete_callback,
#    :post_create_callback, :post_get_callback, :post_update_callback, :post_delete_callback,
#    :from_json, :extract_date])

  defmacro __using__(options) do
    # Only include implementation for these methods.
    #option_arg = Keyword.get(options, :only, @methods)
    #only = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Don't include implementation for these methods.
    #option_arg = Keyword.get(options, :override, [])
    #override = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Final set of methods to provide implementations for.
    #required? = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, only[method] && !override[method]) end)

    # Implementation for Persistance layer interactions.
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Scaffolding.V1_1.RepoBehaviour.AmnesiaProvider)

    # Auditing details
    audit_engine = Keyword.get(options, :audit_engine, Application.get_env(:noizu_scaffolding, :default_audit_engine, Noizu.Scaffolding.AuditEngine.Default))

    quote do
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      @behaviour Noizu.Scaffolding.RepoBehaviour
      @implementation (unquote(implementation_provider))




      a__nzdo__telemetry = cond do
                             Module.has_attribute?(__MODULE__, :telemetry) ->
                               case Module.get_attribute(__MODULE__, :telemetry) do
                                 true ->
                                   Application.get_env(:noizu_scaffolding, :default_enabled_telemetry, [enabled: true, sample_rate: 250, reads: false])
                                 :enabled -> [enabled: true, sample_rate: 250, reads: false]
                                 :light -> [enabled: true, sample_rate: 50, reads: false]
                                 :diagnostic -> [enabled: true, sample_rate: 1000, reads: true]
                                 {:enabled, opts} -> [enabled: true, sample_rate: opts[:sample_rate] || 250, reads: opts[:reads] || false]
                                 false -> [enabled: false, sample_rate: 0, reads: false]
                                 _ -> Application.get_env(:noizu_scaffolding, :default_telemetry, [enabled: false, sample_rate: 0, reads: false])
                               end
                             v = unquote(options[:telemetry]) ->
                               case v do
                                 true ->
                                   Application.get_env(:noizu_scaffolding, :default_enabled_telemetry, [enabled: true, sample_rate: 250, reads: false])
                                 :enabled -> [enabled: true, sample_rate: 250, reads: false]
                                 :light -> [enabled: true, sample_rate: 50, reads: false]
                                 :diagnostic -> [enabled: true, sample_rate: 1000, reads: true]
                                 {:enabled, opts} -> [enabled: true, sample_rate: opts[:sample_rate] || 250, reads: opts[:reads] || false]
                                 false -> [enabled: false, sample_rate: 0, reads: false]
                                 _ -> Application.get_env(:noizu_scaffolding, :default_telemetry, [enabled: false, sample_rate: 0, reads: false])
                               end
                             :else ->
                               Application.get_env(:noizu_scaffolding, :default_telemetry, [enabled: false, sample_rate: 0, reads: false])
                           end
      @__nzdo__telemetry a__nzdo__telemetry
      def __persistence__(:telemetry), do: @__nzdo__telemetry

      #=====================================================================
      # Telemetry
      #=====================================================================
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def emit_telemetry?(type, _, _, options) do
        c = __persistence__(:telemetry)
        cond do
          options[:emity_telemetry] -> true
          context.options[:emit_telemetry] -> true
          !c[:enabled] -> false
          type in [:create, :update, :delete, :create!, :update!, :delete!] || (type in [:get,:get!]) && c[:reads] ->
            cond do
              c[:sample_rate] >= 1000 -> true
              :rand.uniform(1000) <= c[:sample_rate] -> true
              :else -> false
            end
          :else -> false
        end
      end

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def telemetry_event(type, _, _, _) do
        [:persistence, :event, type]
      end







      use unquote(implementation_provider), unquote(options)

      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def audit_engine, do: unquote(audit_engine)

      #-------------------------------------------------------------------------
      # from_json
      #-------------------------------------------------------------------------
      @file unquote(__ENV__.file) <> ":#{unquote(__ENV__.line)}" <> "(via #{__ENV__.file}:#{__ENV__.line})"
      def from_json(_json, _context) do
        throw "From Json Not Implemented For #{__MODULE__}.  use override: from_json and provide your implementation."
      end # end from_json/2

      defoverridable [
        telemetry_event: 4,
        emity_telemtry?: 4,
        audit_engine: 0,
        from_json: 2,
#
#        entity: 0,
#        options: 0,
#        generate_identifier: 0,
#        generate_identifier: 1,
#        generate_identifier!: 0,
#        generate_identifier!: 1,
#        cache_key: 1,
#        cache_key: 2,
#        delete_cache: 2,
#        delete_cache: 3,
#        cached: 2,
#        cached: 3,
#
#        match: 2,
#        match: 3,
#        match!: 2,
#        match!: 3,
#        list: 1,
#        list: 2,
#        list!: 1,
#        list!: 2,
#
#        post_get_callback: 3,
#        get: 2,
#        get: 3,
#        get!: 2,
#        get!: 3,
#
#        pre_update_callback: 3,
#        post_update_callback: 3,
#        update: 2,
#        update: 3,
#        update!: 2,
#        update!: 3,
#
#        pre_delete_callback: 3,
#        post_delete_callback: 3,
#        delete: 2,
#        delete: 3,
#        delete!: 2,
#        delete!: 3,
#
#        pre_create_callback: 3,
#        post_create_callback: 3,
#        create: 2,
#        create: 3,
#        create!: 2,
#        create!: 3,
#
#        extract_date: 1
      ]

    end # end quote
  end # end defmacro __using__(options)
end # end defmodule Noizu.Scaffolding.RepoBehaviour
