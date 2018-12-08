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
    # Implementation for Persistance layer interactions.
    implementation_provider = Keyword.get(options, :implementation_provider,  Noizu.Scaffolding.V2.RepoBehaviour.AmnesiaProvider)

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


      # @deprecated
      def entity(), do: @entity_module

      #-------------------------------------------------------------------------
      # from_json/2, from_json/3
      #-------------------------------------------------------------------------
      def from_json(json, context), do: from_json(:default, json, context)
      def from_json(version, json, context), do: _imp_from_json(@module, version, json, context)
      defdelegate _imp_from_json(m, version, json, context), to: @implementation

      #-------------------------------------------------------------------------
      # extract_date/3
      #-------------------------------------------------------------------------
      defdelegate extract_date(d), to: @implementation

      #-------------------------------------------------------------------------
      # generate_identifier/1
      #-------------------------------------------------------------------------
      def generate_identifier(options \\ nil), do: @nmid_generator.generate(sequencer(), options)

      #-------------------------------------------------------------------------
      # generate_identifier!/1
      #-------------------------------------------------------------------------
      def generate_identifier!(options \\ nil), do: @nmid_generator.generate!(sequencer(), options)


      #==============================
      # @match
      #==============================

      #-------------------------------------------------------------------------
      # match/3
      #-------------------------------------------------------------------------
      def match(match_sel, context, options \\ %{}), do: _imp_match(@module, match_sel, context, options)
      defdelegate _imp_match(module, match_sel, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # match!/3
      #-------------------------------------------------------------------------
      def match!(match_sel, context, options \\ %{}), do: _imp_match!(@module, match_sel, context, options)
      defdelegate _imp_match!(module, match_sel, context, options), to: @implementation


      #==============================
      # @list
      #==============================

      #-------------------------------------------------------------------------
      # list/2
      #-------------------------------------------------------------------------
      def list(context, options \\ %{}), do: _imp_list(@module, context, options)
      defdelegate _imp_list(module, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # list!/2
      #-------------------------------------------------------------------------
      def list!(context, options \\ %{}), do: _imp_list!(@module, context, options)
      defdelegate _imp_list!(module, context, options), to: @implementation


      #==============================
      # @get
      #==============================

      #-------------------------------------------------------------------------
      # post_get_callback/3
      #-------------------------------------------------------------------------
      def post_get_callback(identifier, context, options \\ %{}), do: _imp_post_get_callback(@module, identifier, context, options)
      defdelegate _imp_post_get_callback(module, identifier, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # get/3
      #-------------------------------------------------------------------------
      def get(identifier, context, options \\ %{}), do: _imp_get(@module, identifier, context, options)
      defdelegate _imp_get(module, identifier, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # get!/3
      #-------------------------------------------------------------------------
      def get!(identifier, context, options \\ %{}), do: _imp_get!(@module, identifier, context, options)
      defdelegate _imp_get!(module, identifier, context, options), to: @implementation


      #==============================
      # @create
      #==============================

      #-------------------------------------------------------------------------
      # pre_create_callback/3
      #-------------------------------------------------------------------------
      def pre_create_callback(entity, context, options \\ %{}), do: _imp_pre_create_callback(@module, entity, context, options)
      defdelegate _imp_pre_create_callback(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # post_create_callback/3
      #-------------------------------------------------------------------------
      def post_create_callback(entity, context, options \\ %{}), do: _imp_post_create_callback(@module, entity, context, options)
      defdelegate _imp_post_create_callback(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # create/3
      #-------------------------------------------------------------------------
      def create(entity, context, options \\ %{}), do: _imp_create(@module, entity, context, options)
      defdelegate _imp_create(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # create!/3
      #-------------------------------------------------------------------------
      def create!(entity, context, options \\ %{}), do: _imp_create!(@module, entity, context, options)
      defdelegate _imp_create!(module, entity, context, options), to: @implementation

      #==============================
      # @update
      #==============================

      #-------------------------------------------------------------------------
      # pre_update_callback/3
      #-------------------------------------------------------------------------
      def pre_update_callback(entity, context, options \\ %{}), do: _imp_pre_update_callback(@module, entity, context, options)
      defdelegate _imp_pre_update_callback(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # post_update_callback/3
      #-------------------------------------------------------------------------
      def post_update_callback(entity, context, options \\ %{}), do: _imp_post_update_callback(@module, entity, context, options)
      defdelegate _imp_post_update_callback(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # update/3
      #-------------------------------------------------------------------------
      def update(entity, context, options \\ %{}), do: _imp_update(@module, entity, context, options)
      defdelegate _imp_update(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # update!/3
      #-------------------------------------------------------------------------
      def update!(entity, context, options \\ %{}), do: _imp_update!(@module, entity, context, options)
      defdelegate _imp_update!(module, entity, context, options), to: @implementation

      #==============================
      # @delete
      #==============================

      #-------------------------------------------------------------------------
      # pre_delete_callback/3
      #-------------------------------------------------------------------------
      def pre_delete_callback(entity, context, options \\ %{}), do: _imp_pre_delete_callback(@module, entity, context, options)
      defdelegate _imp_pre_delete_callback(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # post_delete_callback/3
      #-------------------------------------------------------------------------
      def post_delete_callback(entity, context, options \\ %{}), do: _imp_post_delete_callback(@module, entity, context, options)
      defdelegate _imp_post_delete_callback(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # delete/3
      #-------------------------------------------------------------------------
      def delete(entity, context, options \\ %{}), do: _imp_delete(@module, entity, context, options)
      defdelegate _imp_delete(module, entity, context, options), to: @implementation

      #-------------------------------------------------------------------------
      # delete!/3
      #-------------------------------------------------------------------------
      def delete!(entity, context, options \\ %{}), do: _imp_delete!(@module, entity, context, options)
      defdelegate _imp_delete!(module, entity, context, options), to: @implementation


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


        from_json: 2,
        from_json: 3,
        extract_date: 1,

        generate_identifier: 1,
        generate_identifier!: 1,
        match: 3,
        match!: 3,
        list: 2,
        list!: 2,


        pre_create_callback: 3,
        post_create_callback: 3,
        create: 3,
        create!: 3,

        pre_update_callback: 3,
        post_update_callback: 3,
        update: 3,
        update!: 3,

        pre_delete_callback: 3,
        post_delete_callback: 3,
        delete: 3,
        delete!: 3,
      ]


    end # end quote
  end # end defmacro __using__(options)
end # end defmodule Noizu.Scaffolding.RepoBehaviour
