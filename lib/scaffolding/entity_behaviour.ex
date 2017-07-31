#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.EntityBehaviour do
  @moduledoc("""
  This Behaviour provides some callbacks needed for the Noizu.ERP (EntityReferenceProtocol) to work smoothly.
  """)

  #-----------------------------------------------------------------------------
  # aliases, imports, uses,
  #-----------------------------------------------------------------------------
  require Logger

  #-----------------------------------------------------------------------------
  # Behaviour definition and types.
  #-----------------------------------------------------------------------------
  @type nmid :: integer | atom | String.t | tuple
  @type entity_obj :: any
  @type entity_record :: any
  @type entity_tuple_reference :: {:ref, module, nmid}
  @type entity_string_reference :: String.t
  @type details :: any
  @type error :: {:error, details}
  @type options :: Map.t | nil

  @callback ref(entity_tuple_reference | entity_obj) :: entity_tuple_reference | error
  @callback sref(entity_tuple_reference | entity_obj) :: entity_string_reference | error
  @callback entity(entity_tuple_reference | entity_obj, options) :: entity_obj | error
  @callback entity!(entity_tuple_reference | entity_obj, options) :: entity_obj | error
  @callback record(entity_tuple_reference | entity_obj, options) :: entity_record | error
  @callback record!(entity_tuple_reference | entity_obj, options) :: entity_record | error

  #-----------------------------------------------------------------------------
  # Defines
  #-----------------------------------------------------------------------------
  @methods([:ref, :sref, :entity, :entity!, :record, :record!, :erp_imp])

  #-----------------------------------------------------------------------------
  # Default Implementations
  #-----------------------------------------------------------------------------
  defmodule DefaultImplementation do
    @macrocallback ref_implementation(module :: Module, table :: Module, sref_prefix :: String.t) :: Macro.t
    @macrocallback sref_implementation(module :: Module, table :: Module, sref_prefix :: String.t) :: Macro.t
    @macrocallback entity_implementation(module :: Module, table :: Module, repo :: Module) :: Macro.t
    @macrocallback entity_txn_implementation(module :: Module, table :: Module, repo :: Module) :: Macro.t
    @macrocallback record_implementation(module :: Module, table :: Module, repo :: Module) :: Macro.t
    @macrocallback record_txn_implementation(module :: Module, table :: Module, repo :: Module) :: Macro.t

    @doc """
      Noizu.ERP Implementation
    """
    @macrocallback erp_imp(entity :: Module, table :: Module) :: Macro.t

    defmacro ref_implementation(module, table, sref_prefix) do
      quote do
        def ref(identifier) when is_integer(identifier) do
          {:ref, unquote(module), identifier}
        end
        def ref("ref." <> unquote(sref_prefix) <> identifier = sref) do
          Noizu.ERP.ref(identifier)
        end
        def ref(identifier) when is_bitstring(identifier) do
          {:ref, unquote(module), String.to_integer(identifier)}
        end
        def ref(identifier) when is_atom(identifier) do
          {:ref, unquote(module), identifier}
        end
        def ref(%unquote(module){} = entity) do
          entity.identifier
        end
        def ref(%unquote(table){} = record) do
          record.identifier
        end
      end # end quote
    end # end defmacro ref

    defmacro sref_implementation(module, table, sref_prefix) do
      quote do
        def sref(identifier) when is_integer(identifier) do
          unquote(sref_prefix) <> identifier
        end
        def sref("ref." <> unquote(sref_prefix) <> identifier = sref) do
          sref
        end
        def sref(identifier) when is_bitstring(identifier) do
          unquote(sref_prefix) <> identifier
        end
        def sref(identifier) when is_atom(identifier) do
          unquote(sref_prefix) <> Atom.to_string(identifier)
        end
        def sref(%unquote(module){} = entity) do
          unquote(sref_prefix) <> entity.identifier
        end
        def sref(%unquote(table){} = record) do
          unquote(sref_prefix) <> record.identifier
        end
      end # end quote
    end # end defmacro ref

    defmacro entity_implementation(module, table, repo) do
      quote do
        def entity(%unquote(module){} = entity, options) when options == %{} or options == nil do
          entity
        end
        def entity(%unquote(table){} = record, options) when options == %{} or options == nil do
          record.entity
        end
        def entity(identifier, options) do
          unquote(repo).get(unquote(module).ref(identifier), Noizu.Scaffolding.CallingContext.internal(), options)
        end
      end # end quote
    end # end defmacro ref

    defmacro entity_txn_implementation(module, table, repo) do
      quote do
        def entity!(%unquote(module){} = entity, options) when options == %{} or options == nil do
          entity
        end
        def entity!(%unquote(table){} = record, options) when options == %{} or options == nil do
          record.entity
        end
        def entity!(identifier, options) do
          unquote(repo).get!(unquote(module).ref(identifier), Noizu.Scaffolding.CallingContext.internal(), options)
        end
      end # end quote
    end # end defmacro ref

    defmacro record_implementation(module, table, repo) do
      quote do
        def record(%unquote(module){} = entity, options) when options == %{} or options == nil do
          unquote(module).as_record(entity)
        end
        def record(%unquote(table){} = record, options) when options == %{} or options == nil do
          record
        end
        def record(identifier, options) do
          entity = unquote(repo).get(unquote(module).ref(identifier), Noizu.Scaffolding.CallingContext.internal(), options)
          unquote(module).as_record(entity)
        end
      end # end quote
    end # end defmacro ref

    defmacro record_txn_implementation(module, table, repo) do
      quote do
        def record!(%unquote(module){} = entity, options) when options == %{} or options == nil do
          unquote(module).as_record(entity)
        end
        def record!(%unquote(table){} = record, options) when options == %{} or options == nil do
          record
        end
        def record!(identifier, options) do
          unquote(repo).get!(unquote(module).ref(identifier), Noizu.Scaffolding.CallingContext.internal(), options)
          unquote(module).as_record(entity)
        end
      end # end quote
    end # end defmacro ref

    defmacro erp_imp(entity, table) do
      quote do
        defimpl Noizu.ERP, for: [unquote(entity), unquote(table)] do
          def ref(o), do: unquote(entity).ref(o)
          def sref(o), do: unquote(entity).sref(o)
          def entity(o, options), do: unquote(entity).entity(o, options)
          def entity!(o, options), do: unquote(entity).entity!(o, options)
          def record(o, options), do: unquote(entity).record(o, options)
          def record!(o, options), do: unquote(entity).record!(o, options)
        end
      end # end quote
    end # end defmacro
  end # end defmodule

  #-----------------------------------------------------------------------------
  # Using Implementation
  #-----------------------------------------------------------------------------
  defmacro __using__(options) do
    # Only include implementation for these methods.
    option_arg = Keyword.get(options, :only, @methods)
    only = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Don't include implementation for these methods.
    option_arg = Keyword.get(options, :override, [])
    override = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, Enum.member?(option_arg, method)) end)

    # Repo module (entity/record implementation), Module name with "Repo" appeneded if :auto
    repo_module = Keyword.get(options, :repo_module, :auto)
    mnesia_table = Keyword.get(options, :mnesia_table)

    # Default Implementation Provider
    default_implementation = Keyword.get(options, :default_implementation, DefaultImplementation)

    sref_prefix = Keyword.get(options, :sref_prefix, "ref.unsupported")

    quote do
      import unquote(__MODULE__)
      @behaviour Noizu.Scaffolding.EntityBehaviour

      # Repo
      if (unquote(repo_module) == :auto) do
        rm = Module.split(__MODULE__) |> Enum.slice(0..-2) |> Module.concat
        m = (Module.split(__MODULE__) |> Enum.slice(-2..-1) |> Atom.to_string) <> "Repo"
        @repo_module Module.concat([rm, m])
      else
        @repo_module(unquote(repo_module))
      end

      if (unquote(only.ref) && !unquote(override.ref)) do
        unquote(default_implementation).ref_implementation(__MODULE__, unquote(mnesia_table), unquote(sref_prefix))
      end
      if (unquote(only.sref) && !unquote(override.sref)) do
        unquote(default_implementation).sref_implementation(__MODULE__, unquote(mnesia_table), unquote(sref_prefix))
      end
      if (unquote(only.entity) && !unquote(override.entity)) do
        unquote(default_implementation).entity_implementation(__MODULE__, unquote(mnesia_table), unquote(repo_module))
      end
      if (unquote(only.entity!) && !unquote(override.entity!)) do
        unquote(default_implementation).entity_txn_implementation(__MODULE__, unquote(mnesia_table), unquote(repo_module))
      end
      if (unquote(only.record) && !unquote(override.record)) do
        unquote(default_implementation).record_implementation(__MODULE__, unquote(mnesia_table), unquote(repo_module))
      end
      if (unquote(only.record!) && !unquote(override.record!)) do
        unquote(default_implementation).record_txn_implementation(__MODULE__, unquote(mnesia_table), unquote(repo_module))
      end
      if (unquote(only.erp_imp) && !unquote(override.erp_imp)) do
        unquote(default_implementation).erp_imp(__MODULE__, unquote(mnesia_table))
      end
    end # end quote
  end # end defmacro
end #end defmodule
