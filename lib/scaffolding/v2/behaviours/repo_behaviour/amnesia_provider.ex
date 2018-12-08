#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V2.RepoBehaviour.AmnesiaProvider do
  use Amnesia
  require Logger

  #--------------
  #
  #--------------
  def expand_options(m, o) do
    entity_table = expand_table(m, Keyword.get(o, :entity_table, :auto))
    entity_module = expand_entity(m, Keyword.get(o, :entity_module, :auto))
    sequencer = case Keyword.get(o, :sequencer, :auto) do
      :auto -> entity_module
      v -> v
    end
    nmid_generator = Keyword.get(o, :nmid_generator, Application.get_env(:noizu_scaffolding, :default_nmid_generator))
    query_strategy = Keyword.get(o, :query_strategy, Noizu.Scaffolding.QueryStrategy.Default)
    audit_engine = Keyword.get(o, :audit_engine, Application.get_env(:noizu_scaffolding, :default_audit_engine, Noizu.Scaffolding.AuditEngine.Default))
    audit_level = Keyword.get(o, :audit_level, Application.get_env(:noizu_scaffolding, :default_audit_level, :silent))

    %{
      input: o,
      entity_table: entity_table,
      entity_module: entity_module,
      nmid_generator: nmid_generator,
      sequencer: sequencer,
      query_strategy: query_strategy,
      audit_engine: audit_engine,
      audit_level: audit_level
    }
  end

  #--------------
  # expand_entity
  #--------------
  def expand_entity(module, :auto) do
    rm = Module.split(module) |> Enum.slice(0..-2) |> Module.concat
    m = (Module.split(module) |> List.last())
    t = String.slice(m, 0..-5) <> "Entity"
    Module.concat([rm, t])
  end
  def expand_entity(_module, e), do: e

  #--------------
  # expand_table
  #--------------
  def expand_table(module, :auto) do
    path = Module.split(module)
    default_database = Module.concat([List.first(path), "Database"])
    root_table =
      Application.get_env(:noizu_scaffolding, :default_database, default_database)
      |> Module.split()
    entity_name = path |> List.last()
    table_name = String.slice(entity_name, 0..-5) <> "Table"
    inner_path = Enum.slice(path, 1..-2)
    Module.concat(root_table ++ inner_path ++ [table_name])
  end #end expand_table
  def expand_table(_module, t), do: t

  #--------------
  #
  #--------------
  def extract_data(nil), do: nil
  def extract_date(%DateTime{} = date), do: date
  def extract_date(date) when is_integer(date), do: DateTime.from_unix(date)
  def extract_date(date) when is_bitstring(date) do
    case DateTime.from_iso8601(date) do
      {:ok, dt, _o} -> dt
      _ -> nil
    end
  end

  #-----------------
  # _imp_from_json
  #-------------------
  def _imp_from_json(m, _version, _json, _context), do: throw "#{m} must override from_json/2 or from_json/3"

  #--------------
  # _imp_match
  #--------------
  def _imp_match(module, match_sel, context, options) do
    strategy = options[:query_strategy] || module.query_strategy()
    if options[:audit] || Enum.member?([:verbose], module.audit_level()) do
      audit_engine = options[:audit_engine] || module.audit_engine()
      audit_engine.audit(:match, :scaffolding, module.entity_module(), context, options)
    end

    case strategy.match(match_sel, module.table(), context, options) do
      nil ->
        []
      :badarg ->
        Logger.warn("#{module.entity_module()}.match -> :badarg")
        []
      m ->
        e = module.entity_module()
        m
        |> Amnesia.Selection.values
        |> Enum.map(fn(x) -> e.entity(x, options) end)
    end
  end

  #--------------
  # _imp_match!
  #--------------
  def _imp_match!(module, match_sel, context, options) do
    m_opt = module.options()
    options = options || %{}
    dirty = Map.get(options, :dirty, m_opt[:dirty])
    frag = Map.get(options, :frag, m_opt[:frag])
    options_b = options |> Map.delete(:frag) |> Map.delete(:dirty)

    cond do
      dirty && frag == :sync -> Amnesia.Fragment.sync(fn ->  module.match(match_sel, context, options_b) end)
      dirty -> Amnesia.Fragment.async(fn ->  module.match(match_sel, context, options_b) end)
      true ->
        Amnesia.Fragment.transaction do
          module.match(match_sel, context, options_b)
        end
    end # end cond do
  end

  #--------------
  # _imp_list
  #--------------
  def _imp_list(module, context, options)  do
    strategy = options[:query_strategy] || module.query_strategy()
    if options[:audit] || Enum.member?([:verbose], module.audit_level()) do
      audit_engine = options[:audit_engine] || module.audit_engine()
      audit_engine.audit(:list, :scaffolding, module.entity_module(), context, options)
    end

    case strategy.list(module.entity_table(), context, options) do
      nil ->
        []
      :badarg ->
        Logger.warn("#{module.entity_module()}.list -> :badarg")
        []
      m ->
        e = module.entity_module()
        m
        |> Amnesia.Selection.values
        |> Enum.map(fn(x) -> e.entity(x, options) end)
    end
  end # end list/3

  #--------------
  # _imp_list!
  #--------------
  def _imp_list!(module, context, options) do
    m_opt = module.options()
    options = options || %{}
    dirty = Map.get(options, :dirty, m_opt[:dirty])
    frag = Map.get(options, :frag, m_opt[:frag])
    options_b = options |> Map.delete(:frag) |> Map.delete(:dirty)
    cond do
      dirty && frag == :sync -> Amnesia.Fragment.sync(fn ->  module.list(context, options_b) end)
      dirty -> Amnesia.Fragment.async(fn ->  module.list(context, options_b) end)
      true ->
        Amnesia.Fragment.transaction do
          module.list(context, options_b)
        end
    end # end cond do
  end

  #--------------
  # _imp_post_get_callback
  #--------------
  def _imp_post_get_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_get
  #--------------
  def _imp_get(module, identifier, context, options) do
    strategy = options[:query_strategy] || module.query_strategy()
    record = strategy.get(identifier, module.entity_table(), context, options)

    em = module.entity_module()

    if options[:audit] || Enum.member?([:very_verbose], module.audit_level()) do
      ref = case record do
        nil -> nil
        _ -> em.ref(record)
      end
      audit_engine = options[:audit_engine] || module.audit_engine()
      audit_engine.audit(:get, :scaffolding, ref, context, options)
    end
    record
    |> em.entity(options)
    |> module.post_get_callback(context, options)
  end # end get/3

  #--------------
  # _imp_get!
  #--------------
  def _imp_get!(module, identifier, context, options) do
    m_opt = module.options()
    options = options || %{}
    dirty = Map.get(options, :dirty, m_opt[:dirty])
    frag = Map.get(options, :frag, m_opt[:frag])
    options = options |> Map.delete(:frag) |> Map.delete(:dirty)
    cond do
      dirty && frag == :sync -> Amnesia.Fragment.sync(fn -> module.get(identifier, context, options) end)
      dirty -> Amnesia.Fragment.async(fn -> module.get(identifier, context, options) end)
      true ->
        Amnesia.Fragment.transaction do
          module.get(identifier, context, options)
        end
    end # end cond do
  end

  #--------------
  # _imp_pre_create_callback
  #--------------
  def _imp_pre_create_callback(module, %{identifier: nil} = entity, _context, _options), do: %{entity| identifier: module.generate_identifier()}
  def _imp_pre_create_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_post_create_callback
  #--------------
  def _imp_post_create_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_create
  #--------------
  def _imp_create(module, entity, context, options) do
    strategy = options[:query_strategy] || module.query_strategy()
    entity = module.pre_create_callback(entity, context, options)
    if (entity.identifier == nil) do
      throw "Cannot Create #{inspect module.entity_module()} with out identifier field set."
    end
    em = module.entity_module()

    ref = entity
          |> em.record(options)
          |> strategy.create(module.entity_table(), context, options)
          |> em.ref()

    cond do
      options[:audit] == false -> :skip
      !Enum.member?([:very_verbose, :verbose, :core], module.audit_level()) -> :skip
      true ->
        audit_engine = options[:audit_engine] || module.audit_engine()
        audit_engine.audit(:create!, :scaffolding, ref, context, options)
    end

    # No need to return actual record as to_mnesia should not be modifying it in a way that would impact the final structure.
    module.post_create_callback(entity, context, options)
  end # end create/3

  #--------------
  # _imp_create!
  #--------------
  def _imp_create!(module, entity, context, options) do
    m_opt = module.options()
    options = options || %{}
    dirty = Map.get(options, :dirty, m_opt[:dirty])
    frag = Map.get(options, :frag, m_opt[:frag])
    options = options |> Map.delete(:frag) |> Map.delete(:dirty)
    cond do
      dirty && frag == :sync -> Amnesia.Fragment.sync(fn -> module.create(entity, context, options) end)
      dirty -> Amnesia.Fragment.async(fn -> module.create(entity, context, options) end)
      true ->
        Amnesia.Fragment.transaction do
          module.create(entity, context, options)
        end
    end # end cond do
  end


  #--------------
  # _imp_pre_update_callback
  #--------------
  def _imp_pre_update_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_post_update_callback
  #--------------
  def _imp_post_update_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_update
  #--------------
  def _imp_update(module, entity, context, options) do
    strategy = options[:query_strategy] || module.query_strategy()
    if entity.identifier == nil, do: throw "Cannot Update #{inspect module.entity_module()} with out identifier field set."
    entity = module.pre_update_callback(entity, context, options)

    em = module.entity_module()
    ref = entity
          |> em.record(options)
          |> strategy.update(module.entity_table(), context, options)
          |> em.ref()

    cond do
      options[:audit] == false -> :skip
      !Enum.member?([:very_verbose, :verbose, :core], module.audit_level()) -> :skip
      true ->
        audit_engine = options[:audit_engine] || module.audit_engine()
        audit_engine.audit(:update!, :scaffolding, ref, context, options)
    end

    module.post_update_callback(entity, context, options)
  end # end update/3

  #--------------
  # _imp_update!
  #--------------
  def _imp_update!(module, entity, context, options) do
    m_opt = module.options()
    options = options || %{}
    dirty = Map.get(options, :dirty, m_opt[:dirty])
    frag = Map.get(options, :frag, m_opt[:frag])
    options = options |> Map.delete(:frag) |> Map.delete(:dirty)
    cond do
      dirty && frag == :sync -> Amnesia.Fragment.sync(fn -> module.update(entity, context, options) end)
      dirty -> Amnesia.Fragment.async(fn -> module.update(entity, context, options) end)
      true ->
        Amnesia.Fragment.transaction do
          module.update(entity, context, options)
        end
    end # end cond do
  end

  #--------------
  # _imp_pre_delete_callback
  #--------------
  def _imp_pre_delete_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_post_delete_callback
  #--------------
  def _imp_post_delete_callback(_module, entity, _context, _options), do: entity

  #--------------
  # _imp_delete
  #--------------
  def _imp_delete(module, entity, context, options) do
    strategy = options[:query_strategy] || module.query_strategy()
    if entity.identifier == nil do
      throw "Cannot Delete #{inspect module.entity_module()} with out identiifer field set."
    end
    entity = module.pre_delete_callback(entity, context, options)

    strategy.delete(entity.identifier, module.entity_table(), context, options)
    ref = entity
          |> module.post_delete_callback(context, options)
          |> module.entity_module.ref()

    cond do
      options[:audit] == false -> :skip
      !Enum.member?([:very_verbose, :verbose, :core], module.audit_level()) -> :skip
      true ->
        audit_engine = options[:audit_engine] || module.audit_engine()
        audit_engine.audit(:delete!, :scaffolding, ref, context, options)
    end

    true
  end # end delete/3

  #--------------
  # _imp_delete!
  #--------------
  def _imp_delete!(module, entity, context, options) do
    m_opt = module.options()
    options = options || %{}
    dirty = Map.get(options, :dirty, m_opt[:dirty])
    frag = Map.get(options, :frag, m_opt[:frag])
    options = options |> Map.delete(:frag) |> Map.delete(:dirty)
    cond do
      dirty && frag == :sync -> Amnesia.Fragment.sync(fn -> module.delete(entity, context, options) end)
      dirty -> Amnesia.Fragment.async(fn -> module.delete(entity, context, options) end)
      true ->
        Amnesia.Fragment.transaction do
          module.delete(entity, context, options)
        end
    end # end cond do
  end

end
