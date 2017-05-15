#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.RepoBehaviour do
  @type ref :: tuple
  @type opts :: Map.t

  alias Noizu.Scaffolding.CallingContext
  alias Noizu.ERP, as: EntityReferenceProtocol

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
     Insert audit record.
  """
  @callback  audit(atom, any, ref, CallingContext.t, any) :: :ok | {:error, any}

  @doc """
     Insert audit record. Transaction Wrapped
  """
  @callback  audit!(atom, any, ref, CallingContext.t, any) :: :ok | {:error, any}

  @doc """
  Cast from json to struct.
  """
  @callback from_json(Map.t, CallingContext.t) :: any

  @doc """
  Keys from mnesia table
  """
  @callback keys() :: list

  @doc """
  Keys from mnesia table (in transaction)
  """
  @callback keys!() :: list

  @doc """
  Table used by repo
  """
  @callback mnesia_table() :: atom

  @doc """
  Struct used by repo
  """
  @callback entity() :: atom

  defmacro __using__(options) do
    r = Keyword.get(options, :only, [
      :audit, :audit!, :generate_identifier!, :generate_identifier,
      :update, :update!, :delete, :delete!, :create, :create!, :get, :get!,
      :list, :list!,
      :pre_create_callback, :pre_update_callback, :pre_delete_callback,
      :post_create_callback, :post_update_callback, :post_delete_callback,
      :keys, :keys!, :mnesia_table, :entity
      ])
    only = %{
      audit: Enum.member?(r, :audit),
      audit!: Enum.member?(r, :audit!),
      list: Enum.member?(r, :list),
      list!: Enum.member?(r, :list!),
      get: Enum.member?(r, :get),
      get!: Enum.member?(r, :get!),
      update: Enum.member?(r, :update),
      update!: Enum.member?(r, :update!),
      delete: Enum.member?(r, :delete),
      delete!: Enum.member?(r, :delete!),
      create: Enum.member?(r, :create),
      create!: Enum.member?(r, :create!),
      generate_identifier: Enum.member?(r, :generate_identifier),
      generate_identifier!: Enum.member?(r, :generate_identifier!),
      pre_create_callback: Enum.member?(r, :pre_create_callback),
      pre_update_callback: Enum.member?(r, :pre_update_callback),
      pre_delete_callback: Enum.member?(r, :pre_delete_callback),
      post_create_callback: Enum.member?(r, :post_create_callback),
      post_update_callback: Enum.member?(r, :post_update_callback),
      post_delete_callback: Enum.member?(r, :post_delete_callback),
      keys: Enum.member?(r, :keys),
      keys!: Enum.member?(r, :keys!),
      mnesia_table: Enum.member?(r, :mnesia_table),
      entity: Enum.member?(r, :entity)
    }

    r = Keyword.get(options, :override, [])
    override = %{
      audit: Enum.member?(r, :audit),
      audit!: Enum.member?(r, :audit!),
      list: Enum.member?(r, :list),
      list!: Enum.member?(r, :list!),
      get: Enum.member?(r, :get),
      get!: Enum.member?(r, :get!),
      update: Enum.member?(r, :update),
      update!: Enum.member?(r, :update!),
      delete: Enum.member?(r, :delete),
      delete!: Enum.member?(r, :delete!),
      create: Enum.member?(r, :create),
      create!: Enum.member?(r, :create!),
      generate_identifier: Enum.member?(r, :generate_identifier),
      generate_identifier!: Enum.member?(r, :generate_identifier!),
      pre_create_callback: Enum.member?(r, :pre_create_callback),
      pre_update_callback: Enum.member?(r, :pre_update_callback),
      pre_delete_callback: Enum.member?(r, :pre_delete_callback),
      post_create_callback: Enum.member?(r, :post_create_callback),
      post_update_callback: Enum.member?(r, :post_update_callback),
      post_delete_callback: Enum.member?(r, :post_delete_callback),
      keys: Enum.member?(r, :keys),
      keys!: Enum.member?(r, :keys!),
      mnesia_table: Enum.member?(r, :mnesia_table),
      entity: Enum.member?(r, :entity)
    }

    default_nmid_generator = Application.get_env(:noizu_scaffolding, :default_nmid_generator)
    nmid_generator = Keyword.get(options, :nmid_generator, default_nmid_generator)

    default_audit_engine = Application.get_env(:noizu_scaffolding, :default_audit_engine)
    audit_engine = Keyword.get(options, :audit_engine, default_audit_engine)

    audit? = Keyword.get(options, :audit?, true)
    query_strategy = Keyword.get(options, :query_strategy, nil)
    #primary_key_field = Keyword.get(options, :primary_key, :identifier)
    generate_on_create = Keyword.get(options, :generate_on_create, true)
    stub = Keyword.get(options, :stub, false)
    mnesia_table = Keyword.get(options, :mnesia_table)
    entity_module = Keyword.get(options, :entity_module)
    sequencer = Keyword.get(options, :sequencer, mnesia_table)

    if entity_module == nil do
       raise "entity_module must be passed when calling RepoBehaviour"
    end

    if mnesia_table == nil do
       raise "mnesia_table must be passed when calling RepoBehaviour"
    end

    quote do
      require Amnesia
      require Amnesia.Fragment
      require Logger
      import unquote(__MODULE__)
      use unquote(mnesia_table)

      @behaviour Noizu.Scaffolding.RepoBehaviour
      @mnesia_table unquote(mnesia_table)
      @entity unquote(entity_module)

      if (unquote(query_strategy)) do
        @query_strategy unquote(query_strategy)
      else
        @query_strategy __MODULE__.DefaultQueryStrategy
      end


      # Define Query Logic, which may be overridden as needed by callers or Repos
      defmodule DefaultQueryStrategy do
        @behaviour Noizu.Scaffolding.QueryBehaviour
        @mnesia_table unquote(mnesia_table)

        def list(%CallingContext{} = _context, _options) do
          @mnesia_table.where 1 == 1
        end

        def get(identifier, %CallingContext{} = _context, _options) do
          @mnesia_table.read(identifier)
        end

        def update(entity, %CallingContext{} = _context, _options) do
          @mnesia_table.write(entity)
        end

        def create(entity, %CallingContext{} = _context, _options) do
          @mnesia_table.write(entity)
        end

        def delete(identifier, %CallingContext{} = _context, _options) do
          @mnesia_table.delete(identifier)
        end
      end

      if (unquote(stub)) do
        def from_json(_json, _context) do
          %unquote(entity_module){}
        end # end from_json/2
      end

      def default_identifier(entity, options) do
        if entity.identifier == nil do
          id = generate_identifier(options)
          %unquote(entity_module){entity| identifier: id}
        else
          entity
        end
      end

      #-------------------------------------------------------------------------
      # keys/0, keys!/0
      #-------------------------------------------------------------------------
      if (unquote(only.keys) && !unquote(override.keys)) do
        def keys do
          @mnesia_table.keys
        end
      end

      if (unquote(only.keys!) && !unquote(override.keys!)) do
        def keys! do
          Amnesia.Fragment.transaction do
            keys()
          end
        end
      end

      #-------------------------------------------------------------------------
      # mnesia_table/0
      #-------------------------------------------------------------------------
      if (unquote(only.mnesia_table) && !unquote(override.mnesia_table)) do
        def mnesia_table do
          @mnesia_table
        end
      end
      #-------------------------------------------------------------------------
      # struct/0
      #-------------------------------------------------------------------------
      if (unquote(only.entity) && !unquote(override.entity)) do
        def entity do
          @entity
        end
      end

      #-------------------------------------------------------------------------
      # generate_identifier/1, generate_identifier!/1
      #-------------------------------------------------------------------------
      if (unquote(only.generate_identifier) && !unquote(override.generate_identifier)) do
        def generate_identifier(options \\ nil) do
          seq = unquote(sequencer)
          unquote(nmid_generator).generate(seq, options)
        end # end generate_identifier/1
      end

      if (unquote(only.generate_identifier!) && !unquote(override.generate_identifier!)) do
        def generate_identifier!(options \\ nil) do
          seq = unquote(sequencer)
          unquote(nmid_generator).generate!(seq, options)
        end # end generate_identifier/1
      end

      #-------------------------------------------------------------------------
      # list/2, list!/2
      #-------------------------------------------------------------------------

      if (unquote(only.list) && !unquote(override.list)) do
        def list(context, options \\ %{})
        def list(%CallingContext{} = context, options) do
          strategy = if options[:query_strategy], do: options[:query_strategy], else: @query_strategy
          if options[:audit] do
              audit(:list, :scaffolding, @mnesia_table, context)
          end
          strategy.list(context, options)
            |> Amnesia.Selection.values
            |> EntityReferenceProtocol.entity(options)
        end # end list/2
      end # end if (unquote(only.list) && !unquote(override.list)) do

      if (unquote(only.list!) && !unquote(override.list!)) do
        def list!(context, options \\ %{})
        def list!(%CallingContext{} = context, options) do
          Amnesia.Fragment.transaction do
            list(context, options)
          end
        end # end list!/2
      end # end if (unquote(only.list!))

      #-------------------------------------------------------------------------
      # get/3, get!/3
      #-------------------------------------------------------------------------
      if (unquote(only.get) && !unquote(override.get)) do
        def get(identifier, context, options \\ %{})
        def get(identifier, %CallingContext{} = context, options) do
          strategy = if options[:query_strategy], do: options[:query_strategy], else: @query_strategy
          record = strategy.get(identifier, context, options)
          if options[:audit] do
            audit(:get, :scaffolding, EntityReferenceProtocol.ref(record), context)
          end

          record
            |> EntityReferenceProtocol.entity(options)
        end # end get/3
      end # emd if (unquote(only.get))

      if (unquote(only.get!) && !unquote(override.get!)) do
        def get!(identifier, context, options \\ %{})
        def get!(identifier, %CallingContext{} = context, options) do
          Amnesia.Fragment.transaction do
            get(identifier, context, options)
          end
        end # end get/3
      end # end if (unquote(only.get!))

      #-------------------------------------------------------------------------
      # update/3, update!/3
      #-------------------------------------------------------------------------
      if (unquote(only.update) && !unquote(override.update)) do
        def update(entity, context, options \\ %{})
        def update(entity, %CallingContext{} = context, options) do
          strategy = if options[:query_strategy], do: options[:query_strategy], else: @query_strategy

          if entity.identifier == nil do
            raise "Cannot Update #{inspect unquote(entity_module)} with out identifier field set."
          end
          entity = pre_update_callback(entity, context, options)

          ref = entity
            |> EntityReferenceProtocol.record(options)
            |> strategy.update(context, options)
            |> EntityReferenceProtocol.ref()
          audit(:update!, :scaffolding, ref, context)

          entity
            |> post_update_callback(context, options)
        end # end update/3
      end # if (unquote(only.update))

      if (unquote(only.update!) && !unquote(override.update!)) do
        def update!(entity, context, options \\ %{})
        def update!(entity, %CallingContext{} = context, options) do
          Amnesia.Fragment.transaction do
            update(entity, context, options)
          end
        end # end update/3
      end # end if (unquote(only.update!))

      if (unquote(only.post_update_callback) && !unquote(override.post_update_callback)) do
        def post_update_callback(entity, _context = %CallingContext{}, _options) do
          entity
        end
      end

      if (unquote(only.pre_update_callback) && !unquote(override.pre_update_callback)) do
        def pre_update_callback(entity, _context = %CallingContext{}, _options) do
          entity
        end
      end

      #-------------------------------------------------------------------------
      # delete/3, delete!/3
      #-------------------------------------------------------------------------
      if (unquote(only.delete) && !unquote(override.delete)) do
        def delete(entity, context, options \\ %{})
        def delete(entity, %CallingContext{} = context, options) do
          strategy = if options[:query_strategy], do: options[:query_strategy], else: @query_strategy
          if entity.identifier == nil do
            raise "Cannot Delete #{inspect unquote(entity_module)} with out identiifer field set."
          end
          entity = pre_delete_callback(entity, context, options)
          strategy.delete(entity.identifier, context, options)
          ref = entity
            |> post_delete_callback(context, options)
            |> EntityReferenceProtocol.ref()
          audit(:delete!, :scaffolding, ref, context)

          true
        end # end delete/3
      end # end if (unquote(only.delete!))

      if (unquote(only.delete!) && !unquote(override.delete!)) do
        def delete!(entity, context, options \\ %{})
        def delete!(entity, %CallingContext{} = context, options) do
          Amnesia.Fragment.transaction do
            delete(entity, context, options)
          end
        end # end delete/3
      end # end if (unquote(only.delete!))

      if (unquote(only.post_delete_callback) && !unquote(override.post_delete_callback)) do
        def post_delete_callback(entity, _context = %CallingContext{}, _options) do
          entity
        end
      end

      if (unquote(only.pre_delete_callback) && !unquote(override.pre_delete_callback)) do
        def pre_delete_callback(entity, _context = %CallingContext{}, _options) do
          entity
        end
      end

      #-------------------------------------------------------------------------
      # create/3, create!/3
      #-------------------------------------------------------------------------
      if (unquote(only.create) && !unquote(override.create)) do
        def create(entity, context, options \\ %{})
        def create(entity, context = %CallingContext{}, options) do
          strategy = if options[:query_strategy], do: options[:query_strategy], else: @query_strategy
          entity = pre_create_callback(entity, context, options)
          if (entity.identifier == nil) do
            raise "Cannot Create #{inspect unquote(entity_module)} with out identiifer field set."
          end

          ref = entity
            |> EntityReferenceProtocol.record(options)
            |> strategy.create(context, options)
            |> EntityReferenceProtocol.ref()

          audit(:create!, :scaffolding, ref, context)

          # No need to return actual record as to_mnesia should not be modifying it in a way that would impact the final structure.
          entity
            |> post_create_callback(context, options)
        end # end create/3
      end # end if (unquote(only.create))

      if (unquote(only.create!) && !unquote(override.create!)) do
        def create!(entity, context, options \\ %{})
        def create!(entity, context = %CallingContext{}, options) do
          Amnesia.Fragment.transaction do
            create(entity, context, options)
          end
        end # end create/3
      end # end if (unquote(only.create!))

      if (unquote(only.post_create_callback) && !unquote(override.post_create_callback)) do
        def post_create_callback(entity, _context = %CallingContext{}, _options) do
          entity
        end
      end

      if (unquote(only.pre_create_callback) && !unquote(override.pre_create_callback)) do
        def pre_create_callback(entity, _context, options) do
            if (unquote(generate_on_create)) do
              entity
                |> default_identifier(options)
            else
              entity
            end
        end
      end


      #-------------------------------------------------------------------------
      # audit/3, audit!/3
      #-------------------------------------------------------------------------
      if (unquote(only.audit) && !unquote(override.audit)) do
        if (unquote(audit?)) do
          def audit(event, details, entity, %CallingContext{} = context, notes \\ nil) do
            ref = entity |> EntityReferenceProtocol.ref()
            unquote(audit_engine).audit(event, details, ref, context, notes)
          end # end audit/3
        end

        if (!unquote(audit?)) do
          def audit(event, details, entity, %CallingContext{} = context, notes \\ nil) do
            :ok
          end # end audit!/3
        end
      end # end if (unquote(only.audit))

      if (unquote(only.audit!) && !unquote(override.audit!)) do
        if (unquote(audit?)) do
          def audit!(event, details, entity, %CallingContext{} = context, notes \\ nil) do
            ref = entity |> EntityReferenceProtocol.ref()
            unquote(audit_engine).audit!(event, details, ref, context, notes)
          end # end audit!/3
        end

        if (!unquote(audit?)) do
          def audit!(event, details, entity, %CallingContext{} = context, notes \\ nil) do
            :ok
          end # end audit!/3
        end
      end # end if (unquote(only.audit!))

      @pre_compile unquote(__MODULE__)
    end # end quote
  end # end defmacro __using__(options)

  defmacro __pre_compile__(_env) do
    quote do
    end # end quote
  end # end defmacro __pre_compile__(_env)


end # end defmodule Noizu.Scaffolding.RepoBehaviour
