#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V2.RepoBehaviour do
  alias Noizu.ElixirCore.CallingContext

  @type ref :: tuple
  @type opts :: Map.t

  @doc """
    Entity repo manages.
  """
  @callback entity() :: any

  @callback audit_engine() :: any
  @callback audit_level() :: any
  @callback entity_module() :: any
  @callback entity_table() :: any
  @callback options() :: any
  @callback query_strategy() :: any
  @callback sequencer() :: any
  @callback nmid_generator() :: any
  @callback implementation() :: any

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
  @callback from_json(Map.t, CallingContext.t, opts) :: any

  @doc """
  Cast from json to struct.
  """
  @callback from_json_version(any, Map.t, CallingContext.t, opts) :: any

  defmacro __using__(options) do
    # Implementation for Persistance layer interactions.
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Scaffolding.V2.RepoBehaviour.AmnesiaProvider)

    options = case Keyword.get(options, :entity_table, :auto) do
      :auto -> Keyword.put(options, :entity_table, Keyword.get(options, :mnesia_table, :auto))
      _ -> options
    end

    quote do
      @behaviour Noizu.Scaffolding.RepoBehaviour
      import unquote(__MODULE__)

      @implementation (unquote(implementation_provider))

      @module __MODULE__
      @options @implementation.expand_options(@module, unquote(options))

      @audit_engine @options[:audit_engine]
      @sequencer @options[:sequencer]
      @audit_level @options[:audit_level]
      @nmid_generator @options[:nmid_generator]
      @entity_table @options[:entity_table]
      @entity_module @options[:entity_module]
      @query_strategy @options[:query_strategy]

      def audit_engine(), do: @audit_engine
      def audit_level(), do: @audit_level
      def entity_module(), do: @entity_module
      def entity_table(), do: @entity_table
      def options(), do: @options
      def query_strategy(), do: @query_strategy
      def sequencer(), do: @sequencer
      def nmid_generator(), do: @nmid_generator

      def implementation(), do: @implementation

      # @deprecated
      def entity(), do: @entity_module

      def cache_key(ref, options \\ nil) do
        sref = @entity_module.sref(ref)
        sref && :"e_c:#{sref}"
      end

      def delete_cache(ref, context, options \\ nil) do
        # @todo use noizu cluster and meta to track applicable servers.
        key = cache_key(ref, options)
        if key do
          FastGlobal.delete(key)
          spawn fn ->
            (options[:nodes] || Node.list())
            |> Task.async_stream(fn(n) -> :rpc.cast(n, FastGlobal, :delete, [key]) end)
            |> Enum.map(&(&1))
          end
          # return
          :ok
        else
          {:error, :ref}
        end
      end

      def cached(ref, context, options \\ nil)
      def cached(nil, _context, _options), do: nil
      def cached(%{__struct__: @entity_module} = entity, _context, _options), do: entity
      def cached(ref, context, options) do
        cache_key = cache_key(ref, options)
        if cache_key do
          ts = :os.system_time(:second)
          identifier = @entity_module.id(ref)
          # @todo setup invalidation scheme
          Noizu.FastGlobal.Cluster.get(cache_key,
            fn() ->
              if Amnesia.Table.wait([@entity_table], 500) == :ok do
                case get!(identifier, context, options) do
                  entity = %{} -> entity
                  nil -> nil
                  _ -> {:fast_global, :no_cache, nil}
                end
              else
                {:fast_global, :no_cache, nil}
              end
            end
          )
        end
      end

      #-------------------------------------------------------------------------
      # from_json/2, from_json/3
      #-------------------------------------------------------------------------
      def from_json(json, context, options \\ %{}), do: from_json_version(:default, json, context, options)
      def from_json_version(version, json, context, options \\ %{}), do: _imp_from_json_version(@module, version, json, context, options)
      defdelegate _imp_from_json_version(m, version, json, context, options), to: @implementation, as: :from_json_version

      #-------------------------------------------------------------------------
      # extract_date/3
      #-------------------------------------------------------------------------
      defdelegate extract_date(d), to: @implementation

      #-------------------------------------------------------------------------
      # generate_identifier/1
      #-------------------------------------------------------------------------
      def generate_identifier(options \\ nil), do: @nmid_generator.generate(sequencer(), options) # todo - defdelegate

      #-------------------------------------------------------------------------
      # generate_identifier!/1
      #-------------------------------------------------------------------------
      def generate_identifier!(options \\ nil), do: @nmid_generator.generate!(sequencer(), options) # todo - defdelegate

      #==============================
      # @match
      #==============================

      #-------------------------------------------------------------------------
      # match/3
      #-------------------------------------------------------------------------
      def match(match_sel, context, options \\ %{}), do: _imp_match(@module, match_sel, context, options)
      defdelegate _imp_match(module, match_sel, context, options), to: @implementation, as: :match

      #-------------------------------------------------------------------------
      # match!/3
      #-------------------------------------------------------------------------
      def match!(match_sel, context, options \\ %{}), do: _imp_match!(@module, match_sel, context, options)
      defdelegate _imp_match!(module, match_sel, context, options), to: @implementation, as: :match!

      #==============================
      # @list
      #==============================

      #-------------------------------------------------------------------------
      # list/2
      #-------------------------------------------------------------------------
      def list(context, options \\ %{}), do: _imp_list(@module, context, options)
      defdelegate _imp_list(module, context, options), to: @implementation, as: :list

      #-------------------------------------------------------------------------
      # list!/2
      #-------------------------------------------------------------------------
      def list!(context, options \\ %{}), do: _imp_list!(@module, context, options)
      defdelegate _imp_list!(module, context, options), to: @implementation, as: :list!

      #==============================
      # @get
      #==============================

      #-------------------------------------------------------------------------
      # inner_get_callback/3
      #-------------------------------------------------------------------------
      def inner_get_callback(identifier, context, options \\ %{}), do: _imp_inner_get_callback(@module, identifier, context, options)
      defdelegate _imp_inner_get_callback(module, identifier, context, options), to: @implementation, as: :inner_get_callback

      #-------------------------------------------------------------------------
      # post_get_callback/3
      #-------------------------------------------------------------------------
      defdelegate post_get_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # get/3
      #-------------------------------------------------------------------------
      def get(identifier, context, options \\ %{}), do: _imp_get(@module, identifier, context, options)
      defdelegate _imp_get(module, identifier, context, options), to: @implementation, as: :get

      #-------------------------------------------------------------------------
      # get!/3
      #-------------------------------------------------------------------------
      def get!(identifier, context, options \\ %{}), do: _imp_get!(@module, identifier, context, options)
      defdelegate _imp_get!(module, identifier, context, options), to: @implementation, as: :get!

      #==============================
      # @create
      #==============================

      #-------------------------------------------------------------------------
      # pre_create_callback/3
      #-------------------------------------------------------------------------
      defdelegate pre_create_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # inner_create_callback/3
      #-------------------------------------------------------------------------
      defdelegate inner_create_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # post_create_callback/3
      #-------------------------------------------------------------------------
      defdelegate post_create_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # create/3
      #-------------------------------------------------------------------------
      defdelegate create(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # create!/3
      #-------------------------------------------------------------------------
      defdelegate create!(entity, context, options \\ %{}), to: @implementation


      #==============================
      # @update
      #==============================

      #-------------------------------------------------------------------------
      # pre_update_callback/3
      #-------------------------------------------------------------------------
      defdelegate pre_update_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # inner_update_callback/3
      #-------------------------------------------------------------------------
      defdelegate inner_update_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # post_update_callback/3
      #-------------------------------------------------------------------------
      defdelegate post_update_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # update/3
      #-------------------------------------------------------------------------
      defdelegate update(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # update!/3
      #-------------------------------------------------------------------------
      defdelegate update!(entity, context, options \\ %{}), to: @implementation

      #==============================
      # @delete
      #==============================

      #-------------------------------------------------------------------------
      # pre_delete_callback/3
      #-------------------------------------------------------------------------
      defdelegate pre_delete_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # inner_delete_callback/3
      #-------------------------------------------------------------------------
      defdelegate inner_delete_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # post_delete_callback/3
      #-------------------------------------------------------------------------
      defdelegate post_delete_callback(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # delete/3
      #-------------------------------------------------------------------------
      defdelegate delete(entity, context, options \\ %{}), to: @implementation

      #-------------------------------------------------------------------------
      # delete!/3
      #-------------------------------------------------------------------------
      defdelegate delete!(entity, context, options \\ %{}), to: @implementation

      defoverridable [
        audit_engine: 0,
        audit_level: 0,
        entity_module: 0,
        entity_table: 0,
        options: 0,
        query_strategy: 0,
        sequencer: 0,
        nmid_generator: 0,

        entity: 0, # deprecated


        cache_key: 1,
        cache_key: 2,

        delete_cache: 2,
        delete_cache: 3,

        cached: 2,
        cached: 3,


        from_json: 2,
        from_json: 3,

        from_json_version: 3,
        from_json_version: 4,
        _imp_from_json_version: 5,

        extract_date: 1,

        generate_identifier: 0,
        generate_identifier: 1,

        generate_identifier!: 0,
        generate_identifier!: 1,

        match: 2,
        match: 3,
        _imp_match: 4,

        match!: 2,
        match!: 3,
        _imp_match!: 4,

        list: 1,
        list: 2,
        _imp_list: 3,

        list!: 1,
        list!: 2,
        _imp_list!: 3,

        inner_get_callback: 2,
        inner_get_callback: 3,
        _imp_inner_get_callback: 4,

        post_get_callback: 2,
        post_get_callback: 3,

        get: 2,
        get: 3,
        _imp_get: 4,

        get!: 2,
        get!: 3,
        _imp_get!: 4,

        pre_create_callback: 2,
        pre_create_callback: 3,

        inner_create_callback: 2,
        inner_create_callback: 3,

        post_create_callback: 2,
        post_create_callback: 3,

        create: 2,
        create: 3,

        create!: 2,
        create!: 3,

        pre_update_callback: 2,
        pre_update_callback: 3,

        inner_update_callback: 2,
        inner_update_callback: 3,

        post_update_callback: 2,
        post_update_callback: 3,

        update: 2,
        update: 3,

        update!: 2,
        update!: 3,

        pre_delete_callback: 2,
        pre_delete_callback: 3,

        inner_delete_callback: 2,
        inner_delete_callback: 3,

        post_delete_callback: 2,
        post_delete_callback: 3,

        delete: 2,
        delete: 3,

        delete!: 2,
        delete!: 3,
      ]


    end # end quote
  end # end defmacro __using__(options)
end # end defmodule Noizu.Scaffolding.RepoBehaviour
