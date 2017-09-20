#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.RepoBehaviour.AmnesiaProvider do
  use Amnesia
  require Logger
  alias Noizu.Scaffolding.CallingContext
  alias Noizu.ERP, as: EntityReferenceProtocol
  @methods([
    :generate_identifier!, :generate_identifier,
    :update, :update!, :delete, :delete!, :create, :create!, :get, :get!,
    :list, :list!, :pre_create_callback, :pre_update_callback, :pre_delete_callback,
    :post_create_callback, :post_update_callback, :post_delete_callback,
    :extract_date
  ])

  defmacro __using__(options) do
    # Only include implementation for these methods.
    option_arg = Keyword.get(options, :only, @methods)
    only = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Don't include implementation for these methods.
    option_arg = Keyword.get(options, :override, [])
    override = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Final set of methods to provide implementations for.
    required? = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, only[method] && !override[method]) end)

    # associated mnesia table and entity
    mnesia_table = Keyword.get(options, :mnesia_table, :auto)
    entity_module = Keyword.get(options, :entity_module, :auto)

    query_strategy = Keyword.get(options, :query_strategy, Noizu.Scaffolding.QueryStrategy.Default)

    audit_engine = Keyword.get(options, :audit_engine, Application.get_env(:noizu_scaffolding, :default_audit_engine, Noizu.Scaffolding.AuditEngine.Default))

    nmid_generator = Keyword.get(options, :nmid_generator, Application.get_env(:noizu_scaffolding, :default_nmid_generator))
    sequencer = Keyword.get(options, :sequencer, :auto)

    quote do
      use Amnesia
      require Logger
      alias Noizu.Scaffolding.CallingContext
      alias Noizu.ERP, as: EntityReferenceProtocol
      import unquote(__MODULE__)

      mnesia_table = if unquote(mnesia_table) == :auto, do: Noizu.Scaffolding.RepoBehaviour.AmnesiaProvider.expand_table(__MODULE__), else: unquote(mnesia_table)
      @mnesia_table(mnesia_table)

      sequencer = if unquote(sequencer) == :auto, do: mnesia_table, else: unquote(sequencer)
      @sequencer(sequencer)

      entity_module = if unquote(entity_module) == :auto, do: Noizu.Scaffolding.RepoBehaviour.AmnesiaProvider.expand_entity(__MODULE__), else: unquote(entity_module)
      @entity_module(entity_module)

      query_strategy = unquote(query_strategy)
      @query_strategy(query_strategy)

      audit_engine = unquote(audit_engine)
      @audit_engine(audit_engine)

      @param_pass_thru({__MODULE__, @entity_module, @mnesia_table, @query_strategy, @audit_engine})

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
      # @list
      #-------------------------------------------------------------------------
      if unquote(required?.list) do
        def list(context, options \\ %{})
        def list(%CallingContext{} = context, options), do: list(@param_pass_thru, context, options)
      end # end required?.list
      if unquote(required?.list!) do
        def list!(context, options \\ %{})
        def list!(%CallingContext{} = context, options), do: list!(@param_pass_thru, context, options)
      end # end required?.list!
      if unquote(required?.get) do
        def get(identifier, context, options \\ %{})
        def get(identifier, %CallingContext{} = context, options), do: get(@param_pass_thru, identifier, context, options)
      end # end required?.list
      if unquote(required?.get!) do
        def get!(identifier, context, options \\ %{})
        def get!(identifier, %CallingContext{} = context, options), do: get!(@param_pass_thru, identifier, context, options)
      end # end required?.list!

      #-------------------------------------------------------------------------
      # @update
      #-------------------------------------------------------------------------
      if unquote(required?.pre_update_callback) do
        def pre_update_callback(entity, context, options), do: pre_update_callback(@param_pass_thru, entity, context, options)
      end # end required?.pre_update_callback
      if unquote(required?.post_update_callback) do
        def post_update_callback(entity, context, options), do: post_update_callback(@param_pass_thru, entity, context, options)
      end # end required?.post_update_callback
      if unquote(required?.update) do
        def update(entity, context, options \\ %{})
        def update(entity, %CallingContext{} = context, options), do: update(@param_pass_thru, entity, context, options)
      end # end required?.update
      if unquote(required?.update!) do
        def update!(entity, context, options \\ %{})
        def update!(entity, %CallingContext{} = context, options), do: update!(@param_pass_thru, entity, context, options)
      end # end required?.update!

      #-------------------------------------------------------------------------
      # @delete
      #-------------------------------------------------------------------------
      if unquote(required?.pre_delete_callback) do
        def pre_delete_callback(entity, context, options), do: pre_delete_callback(@param_pass_thru, entity, context, options)
      end # end required?.pre_delete_callback
      if unquote(required?.post_delete_callback) do
        def post_delete_callback(entity, context, options), do: post_delete_callback(@param_pass_thru, entity, context, options)
      end # end required?.post_delete_callback
      if unquote(required?.delete) do
        def delete(entity, context, options \\ %{})
        def delete(entity, %CallingContext{} = context, options), do: delete(@param_pass_thru, entity, context, options)
      end # end  required?.delete
      if unquote(required?.delete!) do
        def delete!(entity, context, options \\ %{})
        def delete!(entity, %CallingContext{} = context, options), do: delete!(@param_pass_thru, entity, context, options)
      end # end required?.delete!

      #-------------------------------------------------------------------------
      # @create
      #-------------------------------------------------------------------------
      if unquote(required?.pre_delete_callback) do
        def pre_create_callback(entity, context, options), do: pre_create_callback(@param_pass_thru, entity, context, options)
      end # end required?.pre_create_callback
      if unquote(required?.post_delete_callback) do
        def post_create_callback(entity, context, options), do: post_create_callback(@param_pass_thru, entity, context, options)
      end # end required?.post_create_callback
      if unquote(required?.create) do
        def create(entity, context, options \\ %{})
        def create(entity, context = %CallingContext{}, options), do: create(@param_pass_thru, entity, context, options)
      end # end required?.create
      if unquote(required?.create!) do
        def create!(entity, context, options \\ %{})
        def create!(entity, context = %CallingContext{}, options), do: create!(@param_pass_thru, entity, context, options)
      end # end required?.create


      if unquote(required?.extract_date) do
        def extract_date(nil), do: nil
        def extract_date(%DateTime{} = date), do: date
        def extract_date(date) when is_integer(date), do: DateTime.from_unix(date)
        def extract_date(date) when is_bitstring(date) do
          {:ok, dt, _o} = DateTime.from_iso8601(date)
          dt
        end
      end

    end # end quote
  end # end __using__

  #-----------------------------------------------------------------------------
  #  Utils
  #-----------------------------------------------------------------------------
  def expand_table(module) do
      path = Module.split(module)
      default_database = Module.concat([List.first(path), "Database"])
      root_table =
        Application.get_env(Noizu.ElixirScaffolding, :default_database, default_database)
        |> Module.split()
      entity_name = path |> List.last()
      table_name = String.slice(entity_name, 0..-5) <> "Table"
      inner_path = Enum.slice(path, 1..-2)
      Module.concat(root_table ++ inner_path ++ [table_name])
  end #end expand_table

  def expand_entity(module) do
      rm = Module.split(module) |> Enum.slice(0..-2) |> Module.concat
      m = (Module.split(module) |> List.last())
      t = String.slice(m, 0..-5) <> "Entity"
      Module.concat([rm, t])
  end # end expand_repo

  #-----------------------------------------------------------------------------
  # Behaviour methods
  #-----------------------------------------------------------------------------
  def list({_mod, entity_module, mnesia_table, query_strategy, audit_engine} = _indicator, %CallingContext{} = context, options) do
    strategy = options[:query_strategy] || query_strategy
    if options[:audit] do
      audit_engine = options[:audit_engine] || audit_engine
      audit_engine.audit(:list, :scaffolding, entity_module, context)
    end

    case strategy.list(mnesia_table, context, options) do
      nil -> []
      :badarg ->
        Logger.warn("#{entity_module}.list -> :badarg")
        []
      m ->
        m
        |> Amnesia.Selection.values
        |> EntityReferenceProtocol.entity(options)
    end
  end # end list/3

  def list!({mod, _entity_module, _mnesia_table, _query_strategy, _audit_engine} = _indicator, %CallingContext{} = context, options) do
    Amnesia.Fragment.transaction  do
       mod.list(context, options)
    end
  end

  def get({_mod, entity_module, mnesia_table, query_strategy, audit_engine} = _indicator, identifier, %CallingContext{} = context, options) do
    strategy = options[:query_strategy] || query_strategy
    record = strategy.get(identifier, mnesia_table, context, options)

    if options[:audit] do
      ref = case record do
        nil -> nil
        _ -> EntityReferenceProtocol.ref(record)
      end
      audit_engine = options[:audit_engine] || audit_engine
      audit_engine.audit(:get, :scaffolding, ref, context)
    end

    entity_module.entity(record, options)
  end # end get/3

  def get!({mod, _entity_module, _mnesia_table, _query_strategy, _audit_engine} = _indicator, identifier, %CallingContext{} = context, options) do
    Amnesia.Fragment.transaction do
      mod.get(identifier, context, options)
    end
  end

  def pre_update_callback(_indicator, entity, _context, _options), do: entity
  def post_update_callback(_indicator, entity, _context, _options), do: entity
  def update({mod, entity_module, mnesia_table, query_strategy, audit_engine} = _indicator, entity, %CallingContext{} = context, options) do
    strategy = options[:query_strategy] || query_strategy
    if entity.identifier == nil, do: raise "Cannot Update #{inspect entity_module} with out identifier field set."
    entity = mod.pre_update_callback(entity, context, options)

    ref = entity
      |> entity_module.record(options)
      |> strategy.update(mnesia_table, context, options)
      |> entity_module.ref()

    audit_engine = options[:audit_engine] || audit_engine
    audit_engine.audit(:update!, :scaffolding, ref, context)

    entity
      |> mod.post_update_callback(context, options)
  end # end update/3

  def update!({mod, _entity_module, _mnesia_table, _query_strategy, _audit_engine} = _indicator, entity, %CallingContext{} = context, options) do
    Amnesia.Fragment.transaction do
      mod.update(entity, context, options)
    end
  end

  def pre_delete_callback(_indicator, entity, _context, _options), do: entity
  def post_delete_callback(_indicator, entity, _context, _options), do: entity
  def delete({mod, entity_module, mnesia_table, query_strategy, audit_engine} = _indicator, entity, %CallingContext{} = context, options) do
    strategy = options[:query_strategy] || query_strategy
    if entity.identifier == nil do
      raise "Cannot Delete #{inspect entity_module} with out identiifer field set."
    end
    entity = mod.pre_delete_callback(entity, context, options)
    strategy.delete(entity.identifier, mnesia_table, context, options)
    ref = entity
      |> mod.post_delete_callback(context, options)
      |> entity_module.ref()

    audit_engine = options[:audit_engine] || audit_engine
    audit_engine.audit(:delete!, :scaffolding, ref, context)

    true
  end # end delete/3

  def delete!({mod, _entity_module, _mnesia_table, _query_strategy, _audit_engine} = _indicator, entity, %CallingContext{} = context, options) do
    Amnesia.Fragment.transaction do
      mod.delete(entity, context, options)
    end
  end

  def pre_create_callback({mod, _entity_module, _mnesia_table, _query_strategy, _audit_engine} = _indicator, entity, _context, _options) do
    if entity.identifier == nil do
      %{entity| identifier: mod.generate_identifier}
    else
      entity
    end
  end
  def post_create_callback(_indicator, entity, _context, _options), do: entity
  def create({mod, entity_module, mnesia_table, query_strategy, audit_engine} = _indicator, entity, context = %CallingContext{}, options) do
    IO.puts "CREATE #{inspect __MODULE__}.create(#{inspect {{mod, entity_module, mnesia_table, query_strategy, audit_engine}, entity}})"
    strategy = options[:query_strategy] || query_strategy
    IO.puts "HERE 1 #{inspect entity}"
    entity = mod.pre_create_callback(entity, context, options)
    IO.puts "HERE 2 #{inspect entity}"
    if (entity.identifier == nil) do
      raise "Cannot Create #{inspect entity_module} with out identiifer field set."
    end
    IO.puts "HERE 3 #{inspect entity_module} ->
      (#{inspect entity}, #{inspect options}) => #{inspect entity_module.record(entity, nil)}"

    ref = entity
      |> entity_module.record(options)
      |> IO.inspect
      |> strategy.create(mnesia_table, context, options)
      |> IO.inspect
      |> entity_module.ref()
      |> IO.inspect

    audit_engine = options[:audit_engine] || audit_engine
    |> IO.inspect
    audit_engine.audit(:create!, :scaffolding, ref, context)
    |> IO.inspect
    # No need to return actual record as to_mnesia should not be modifying it in a way that would impact the final structure.
    entity
      |> mod.post_create_callback(context, options)
      |> IO.inspect
  end # end create/3

  def create!({mod, _entity_module, _mnesia_table, _query_strategy, _audit_engine} = _indicator, entity, %CallingContext{} = context, options) do
    IO.puts "CREATE! #{inspect mod}.create(#{inspect {entity, context, options}})"
    Amnesia.Fragment.transaction do
      mod.create(entity, context, options)
    end
  end
end
