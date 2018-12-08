#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V2.EntityBehaviourDefault do
    @callback ref_implementation(table :: Module, sref_prefix :: String.t) :: Macro.t
    @callback miss_cb_implementation() :: Macro.t
    @callback sref_implementation(table :: Module, sref_prefix :: String.t) :: Macro.t
    @callback entity_implementation(table :: Module, repo :: Module) :: Macro.t
    @callback entity_txn_implementation(table :: Module, repo :: Module) :: Macro.t
    @callback record_implementation(table :: Module, repo :: Module) :: Macro.t
    @callback record_txn_implementation(table :: Module, repo :: Module) :: Macro.t
    @callback as_record_implementation(Module, options :: nil | Map.t) :: any
    @callback expand_table(Module, Module) :: Module
    @callback expand_repo(Module, Module) :: Module



    def compress_implementation(m, entity, options), do: entity
    def expand_implementation(m, entity, options), do: entity

    #-----------------
    # id_implementation
    #-------------------
    def id_implementation(_m, nil), do: nil
    def id_implementation(m, {:ref, m, identifier} = _ref), do: identifier
    def id_implementation(m, %{__struct__: m, identifier: identifier}), do: identifier
    def id_implementation(m, %{__struct__: struct, identifier: identifier}), do: struct == m.table() && identifier
    def id_implementation(_m, ref) when is_atom(ref), do: ref
    def id_implementation(_m, ref) when is_integer(ref), do: ref
    def id_implementation(_m, ref) when is_bitstring(ref) do
      case ref do
        "ref." <> _ -> nil
        id ->
          case Integer.parse(id) do
            {id, ""} -> id
            _ -> nil
          end
      end
    end

    #-----------------
    # ref_implementation
    #-------------------
    def ref_implementation(m, {:ref, m, identifier} = _ref), do: {:ref, m, identifier}
    def ref_implementation(m, %{__struct__: m, identifier: identifier}), do: {:ref, m, identifier}
    def ref_implementation(m, %{__struct__: struct, identifier: identifier}), do: struct == m.table() && {:ref, m, identifier}
    def ref_implementation(m, ref), do: (id = m.id(ref)) && {:ref, m, id}

    #-----------------
    # sref_implementation
    #-------------------
    def sref_implementation(m, {:ref, m, identifier} = _ref), do: "#{m.sref_prefix}#{identifier}"
    def sref_implementation(m, %{__struct__: m, identifier: identifier}), do: "#{m.sref_prefix}#{identifier}"
    def sref_implementation(m, %{__struct__: struct, identifier: identifier}), do: struct == m.table() && "#{m.sref_prefix}#{identifier}"
    def sref_implementation(m, ref), do: (id = m.id(ref)) && "#{m.sref_prefix}#{id}"

    #-----------------
    # miss_cb_implementation
    #-------------------
    def miss_cb_implementation(_m, _ref, _options \\ nil), do: nil

    #-----------------
    # entity_implementation
    #-------------------
    def entity_implementation(m, {:ref, m, identifier} = _ref, options) do
      context = options[:context] || Noizu.ElixirCore.CallingContext.system()
      m.repo().get(identifier, context, options) || m.miss_cb(identifier, options)
    end
    def entity_implementation(m, %{__struct__: m} = entity, _options), do: entity
    def entity_implementation(m, %{__struct__: struct} = entity, options) do
      struct == m.table() && m.expand(entity.entity, options[:compressions] || %{})
    end
    def entity_implementation(m, ref, options) do
      identifier = m.id(ref)
      if identifier do
        context = options[:context] || Noizu.ElixirCore.CallingContext.system()
        m.repo().get(identifier, context, options) || m.miss_cb(identifier, options)
      end
    end

    #-----------------
    # entity_txn_implementation
    #-------------------
    def entity_txn_implementation(m, {:ref, m, identifier} = _ref, options) do
      context = options[:context] || Noizu.ElixirCore.CallingContext.system()
      m.repo().get!(identifier, context, options) || m.miss_cb(identifier, options)
    end
    def entity_txn_implementation(m, %{__struct__: m} = entity, _options), do: entity
    def entity_txn_implementation(m, %{__struct__: struct} = entity, options) do
      struct == m.table() && m.expand(entity.entity, options[:compressions] || %{})
    end
    def entity_txn_implementation(m, ref, options) do
      identifier = m.id(ref)
      if identifier do
        context = options[:context] || Noizu.ElixirCore.CallingContext.system()
        m.repo().get!(identifier, context, options) || m.miss_cb(identifier, options)
      end
    end

    #-----------------
    # record_implementation
    #-------------------
    def record_implementation(m, %{__struct__: m} = entity, options), do: m.as_record(entity, options)
    def record_implementation(m, %{__struct__: struct} = entity, _options) do
      struct == m.table() && entity
    end
    def record_implementation(m, ref, options) do
      entity = m.entity(ref, options)
      entity && m.as_record(entity, options)
    end

    #-----------------
    # record_txn_implementation
    #-------------------
    def record_txn_implementation(m, %{__struct__: m} = entity, options), do: m.as_record(entity, options)
    def record_txn_implementation(m, %{__struct__: struct} = entity, _options) do
      struct == m.table() && entity
    end
    def record_txn_implementation(m, ref, options) do
      entity = m.entity!(ref, options)
      entity && m.as_record(entity, options)
    end

    #-----------------
    # has_permission_implementation
    #-------------------
    def has_permission_implementation(_m, _ref, _permission, %{auth: auth}, _options) do
      auth[:permissions][:admin] || auth[:permissions][:system] || false
    end
    def has_permission_implementation(_m, _ref, _permission, _context, _options), do: false

    #-----------------
    # has_permission_txn_implementation
    #-------------------
    def has_permission_txn_implementation(_m, _ref, _permission, %{auth: auth}, _options) do
      auth[:permissions][:admin] || auth[:permissions][:system] || false
    end
    def has_permission_txn_implementation(_m, _ref, _permission, _context, _options), do: false

    #-----------------
    # as_record_implementation
    #-------------------
    def as_record_implementation(m, %{__struct__: m, identifier: identifier} = entity, options) do
      base = m._int_empty_record()
             |> put_in([Access.key(:identifier)], identifier)
             |> put_in([Access.key(:entity)], m.compress(entity, options[:compression] || %{}))

      case m._int_as_record_options() do
        %{additional_fields: af} when is_list(af) ->
          Enum.reduce(af, base,
            fn(field, acc) ->
              case Map.get(entity, field, :erp_imp_field_not_found) do
                :erp_imp_field_not_found -> acc
                %DateTime{} = v -> put_in(acc, [Access.key(field)], DateTime.to_unix(v))
                %{__struct__: s} = v ->
                  try do
                    if s._int_entity?() do
                      put_in(acc, [Access.key(field)], s.ref(v))
                    else
                      put_in(acc, [Access.key(field)], v)
                    end
                  rescue _ -> put_in(acc, [Access.key(field)], v)
                  catch _ -> put_in(acc, [Access.key(field)], v)
                  end
                v -> put_in(acc, [Access.key(field)], v)
              end
            end)
        _ -> base
      end
    end
    def as_record_implementation(_m, _ref, _options), do: nil

    #-----------------
    # expand_table
    #-------------------
    def expand_table(module, table) do
      # Apply Schema Naming Convention if not specified
      if (table == :auto) do
        path = Module.split(module)
        default_database = Module.concat([List.first(path), "Database"])
        root_table =
          Application.get_env(:noizu_scaffolding, :default_database, default_database)
          |> Module.split()
        entity_name = path |> List.last()
        table_name = String.slice(entity_name, 0..-7) <> "Table"
        inner_path = Enum.slice(path, 1..-2)
        Module.concat(root_table ++ inner_path ++ [table_name])
      else
        table
      end
    end #end expand_table

    #-----------------
    # expand_repo
    #-------------------
    def expand_repo(module, repo) do
      if (repo == :auto) do
        rm = Module.split(module) |> Enum.slice(0..-2) |> Module.concat
        m = (Module.split(module) |> List.last())
        t = String.slice(m, 0..-7) <> "Repo"
        Module.concat([rm, t])
      else
        repo
      end
    end # end expand_repo
  end # end defmodule