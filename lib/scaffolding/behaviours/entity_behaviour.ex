#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.EntityBehaviour do
  @moduledoc """
  This Behaviour provides some callbacks needed for the Noizu.ERP (EntityReferenceProtocol) to work smoothly.

  Note the following naming conventions  (where Path.To.Entity is the same path in each following case)
  - Entities  MyApp.(Path.To.Entity).MyFooEntity
  - Tables    MyApp.MyDatabase.(Path.To.Entity).MyFooTable
  - Repos     MyApp.(Path.To.Entity).MyFooRepo

  If the above conventions are not used a framework user must provide the appropriate `mnesia_table`, and `repo_module` `use` options.
  """
  alias Noizu.ElixirCore.CallingContext
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
  @type entity_reference :: entity_obj | entity_record | entity_tuple_reference | entity_string_reference
  @type details :: any
  @type error :: {:error, details}
  @type options :: Map.t | nil

  @doc """
    Return identifier of ref, sref, entity or record
  """
  @callback id(entity_reference) :: any | error

  @doc """
    Returns appropriate {:ref|:ext_ref, module, identifier} reference tuple
  """
  @callback ref(entity_reference) :: entity_tuple_reference | error

  @doc """
    Returns appropriate string encoded ref. E.g. ref.user.1234
  """
  @callback sref(entity_reference) :: entity_string_reference | error

  @doc """
    Returns entity, given an identifier, ref tuple, ref string or other known identifier type.
    Where an entity is a EntityBehaviour implementing struct.
  """
  @callback entity(entity_reference, options) :: entity_obj | error

  @doc """
    Returns entity, given an identifier, ref tuple, ref string or other known identifier type. Wrapping call in transaction if required.
    Where an entity is a EntityBehaviour implementing struct.
  """
  @callback entity!(entity_reference, options) :: entity_obj | error

  @doc """
    Returns record, given an identifier, ref tuple, ref string or other known identifier type.
    Where a record is the raw mnesia table entry, as opposed to a EntityBehaviour based struct object.
  """
  @callback record(entity_reference, options) :: entity_record | error

  @doc """
    Returns record, given an identifier, ref tuple, ref string or other known identifier type. Wrapping call in transaction if required.
    Where a record is the raw mnesia table entry, as opposed to a EntityBehaviour based struct object.
  """
  @callback record!(entity_reference, options) :: entity_record | error

  @callback has_permission(entity_reference, any, any, options) :: boolean | error
  @callback has_permission!(entity_reference, any, any, options) :: boolean | error

  @doc """
    Converts entity into record format. Aka extracts any fields used for indexing with the expected database table looking something like
    ```
      %Table{
        identifier: entity.identifier,
        ...
        any_indexable_fields: entity.indexable_field,
        ...
        entity: entity
      }
    ```
    The default implementation assumes table structure if simply `%Table{identifier: entity.identifier, entity: entity}` therefore you will need to
    overide this implementation if you have any indexable fields. Future versions of the entity behaviour will accept an indexable field option
    that will insert expected fields and (if indicated) do simple type casting such as transforming DateTime.t fields into utc time stamps or
    `{time_zone, year, month, day, hour, minute, second}` tuples for efficient range querying.
  """
  @callback as_record(entity_obj) :: entity_record | error

  @doc """
    Returns the string used for preparing sref format strings. E.g. a `User` struct might use the string ``"user"`` as it's sref_module resulting in
    sref strings like `ref.user.1234`.
  """
  @callback sref_module() :: String.t

  @doc """
  Cast from json to struct.
  """
  @callback from_json(Map.t, CallingContext.t) :: any

  @doc """
  get entitie's repo module
  """
  @callback repo() :: atom

  #-----------------------------------------------------------------------------
  # Defines
  #-----------------------------------------------------------------------------
  @methods [:id, :ref, :sref, :entity, :entity!, :record, :record!, :erp_imp, :as_record, :sref_module, :as_record, :from_json, :repo, :shallow, :miss_cb]

  #-----------------------------------------------------------------------------
  # Default Implementations
  #-----------------------------------------------------------------------------
  defmodule DefaultImplementation do
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



    @doc """
      Noizu.ERP Implementation
    """
    @callback erp_imp(table :: Module) :: Macro.t

    def id_implementation(table, sref_prefix) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        def id(nil), do: nil
        def id({:ref, __MODULE__, identifier} = _ref), do: identifier
        def id(%__MODULE__{} = entity), do: entity.identifier
        def id(unquote(sref_prefix) <> identifier), do: __MODULE__.ref(identifier) |> __MODULE__.id()
        def id(%@table{} = record), do: record.identifier
      end # end quote
    end

    def ref_implementation(table, sref_prefix) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        def ref(nil), do: nil
        def ref({:ref, __MODULE__, _identifier} = ref), do: ref
        def ref(identifier) when is_integer(identifier), do: {:ref, __MODULE__, identifier}
        def ref(unquote(sref_prefix) <> identifier = _sref), do: ref(identifier)
        def ref(identifier) when is_bitstring(identifier), do: {:ref, __MODULE__, String.to_integer(identifier)}
        def ref(identifier) when is_atom(identifier), do: {:ref, __MODULE__, identifier}
        def ref(%__MODULE__{} = entity), do: {:ref, __MODULE__, entity.identifier}
        def ref(%@table{} = record), do: {:ref, __MODULE__, record.identifier}
        def ref(any), do: raise "#{__MODULE__}.ref Unsupported item #{inspect any}"
      end # end quote
    end # end ref_implementation

    def sref_implementation(table, sref_prefix) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        def sref(nil), do: nil
        def sref(identifier) when is_integer(identifier), do: "#{unquote(sref_prefix)}#{identifier}"
        def sref(unquote(sref_prefix) <> identifier = sref), do: sref
        def sref(identifier) when is_bitstring(identifier), do: ref(identifier) |> sref()
        def sref(identifier) when is_atom(identifier), do: "#{unquote(sref_prefix)}#{identifier}"
        def sref(%__MODULE__{} = this), do: "#{unquote(sref_prefix)}#{this.identifier}"
        def sref(%@table{} = record), do: "#{unquote(sref_prefix)}#{record.identifier}"
        def sref(any), do: raise "#{__MODULE__}.sref Unsupported item #{inspect any}"
      end # end quote
    end # end sref_implementation


    def miss_cb_implementation() do
      quote do
        def miss_cb(id, options \\ nil)
        def miss_cb(id, _options), do: nil
      end # end quote
    end # end entity_implementation

    def entity_implementation(table, repo) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        @repo unquote(__MODULE__).expand_repo(__MODULE__, unquote(repo))
        def entity(item, options \\ nil)
        def entity(nil, _options), do: nil
        def entity(%__MODULE__{} = this, options), do: this
        def entity(%@table{} = record, options), do: record.entity
        def entity(identifier, options) do
          @repo.get(__MODULE__.id(identifier), Noizu.ElixirCore.CallingContext.internal(), options) || __MODULE__.miss_cb(identifier, options)
        end
      end # end quote
    end # end entity_implementation

    def entity_txn_implementation(table, repo) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        @repo unquote(__MODULE__).expand_repo(__MODULE__, unquote(repo))
        def entity!(item, options \\ nil)
        def entity!(nil, _options), do: nil
        def entity!(%__MODULE__{} = this, options), do: this
        def entity!(%@table{} = record, options), do: record.entity
        def entity!(identifier, options), do: @repo.get!(__MODULE__.ref(identifier) |> __MODULE__.id(), Noizu.ElixirCore.CallingContext.internal(), options) || __MODULE__.miss_cb(identifier, options)
      end # end quote
    end # end entity_txn_implementation

    def record_implementation(table, repo) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        @repo unquote(__MODULE__).expand_repo(__MODULE__, unquote(repo))
        def record(item, options \\ nil)
        def record(nil, _options), do: nil
        def record(%__MODULE__{} = this, options), do: __MODULE__.as_record(this)
        def record(%@table{} = record, options), do: record
        def record(identifier, options), do: __MODULE__.as_record(@repo.get(__MODULE__.ref(identifier) |> __MODULE__.id(), Noizu.ElixirCore.CallingContext.internal(), options)) |> __MODULE__.as_record()
      end # end quote
    end # end record_implementation

    def record_txn_implementation(table, repo) do
      quote do
        @table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        @repo unquote(__MODULE__).expand_repo(__MODULE__, unquote(repo))
        def record!(item, options \\ nil)
        def record!(nil, _options), do: nil
        def record!(%__MODULE__{} = this, options), do: __MODULE__.as_record(this)
        def record!(%@table{} = record, options), do: record
        def record!(identifier, options), do: @repo.get!(__MODULE__.ref(identifier) |> __MODULE__.id(), Noizu.ElixirCore.CallingContext.internal(), options) |> __MODULE__.as_record()
      end # end quote
    end # end record_txn_implementation

    def erp_imp(table) do
      quote do
        parent_module = __MODULE__
        mnesia_table = unquote(__MODULE__).expand_table(parent_module, unquote(table))
        defimpl Noizu.ERP, for: [__MODULE__, mnesia_table] do
          @parent_module parent_module
          def id(o), do: @parent_module.id(o)
          def ref(o), do: @parent_module.ref(o)
          def sref(o), do: @parent_module.sref(o)
          def entity(o, options \\ nil), do: @parent_module.entity(o, options)
          def entity!(o, options \\ nil), do: @parent_module.entity!(o, options)
          def record(o, options \\ nil), do: @parent_module.record(o, options)
          def record!(o, options \\ nil), do: @parent_module.record!(o, options)
        end
      end # end quote
    end # end erp_imp

    def as_record_implementation(table, options) do
      quote do
        @mnesia_table unquote(__MODULE__).expand_table(__MODULE__, unquote(table))
        @options unquote(options)
        def as_record(nil), do: nil
        if @options != nil do
          if Map.has_key?(@options, :additional_fields) do
            def as_record(this) do
              base = %@mnesia_table{identifier: this.identifier, entity: this}
              List.foldl(@options[:additional_fields], base,
                fn(field, acc) ->
                  case Map.get(this, field, :erp_imp_field_not_found) do
                    :erp_imp_field_not_found -> acc
                    %DateTime{} = v -> Map.put(acc, field, DateTime.to_unix(v))
                    v -> Map.put(acc, field, v)
                  end
                end
              )
            end
          else
            def as_record(this) do
              %@mnesia_table{identifier: this.identifier, entity: this}
            end
          end
        else
          def as_record(this) do
            %@mnesia_table{identifier: this.identifier, entity: this}
          end
        end
      end # end quote
    end # end as_record_implementation

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

    required? = List.foldl(@methods, %{}, fn(method, acc) -> Map.put(acc, method, only[method] && !override[method]) end)

    # Repo module (entity/record implementation), Module name with "Repo" appeneded if :auto
    repo_module = Keyword.get(options, :repo_module, :auto)
    mnesia_table = Keyword.get(options, :mnesia_table, :auto)


    as_record_options = Keyword.get(options, :as_record_options, Macro.escape(%{}))

    # Default Implementation Provider
    default_implementation = Keyword.get(options, :default_implementation, DefaultImplementation)

    sm = Keyword.get(options, :sref_module, "unsupported")
    sref_prefix = "ref." <> sm <> "."

    quote do
      import unquote(__MODULE__)
      @behaviour Noizu.Scaffolding.EntityBehaviour

      @expanded_repo unquote(default_implementation).expand_repo(__MODULE__, unquote(repo_module))

      if unquote(required?.sref_module) do
        def sref_module(), do: unquote(sm)
      end

      if unquote(required?.repo) do
        def repo(), do: @expanded_repo
      end

      #-------------------------------------------------------------------------
      # Default Implementation from default_implementation behaviour
      #-------------------------------------------------------------------------
      if unquote(required?.from_json) do
        def from_json(json, context) do
           @expanded_repo.from_json(json, context)
         end
      end

      if unquote(required?.shallow) do
        def shallow(identifier) do
          %__MODULE__{identifier: identifier}
        end
      end

      #unquote(Macro.expand(default_implementation, __CALLER__).prepare(mnesia_table, repo_module, sref_prefix))

      if unquote(required?.id), do: unquote(Macro.expand(default_implementation, __CALLER__).id_implementation(mnesia_table, sref_prefix))
      if unquote(required?.ref), do: unquote(Macro.expand(default_implementation, __CALLER__).ref_implementation(mnesia_table, sref_prefix))
      if unquote(required?.sref), do: unquote(Macro.expand(default_implementation, __CALLER__).sref_implementation(mnesia_table, sref_prefix))
      if unquote(required?.miss_cb), do: unquote(Macro.expand(default_implementation, __CALLER__).miss_cb_implementation())
      if unquote(required?.entity), do: unquote(Macro.expand(default_implementation, __CALLER__).entity_implementation(mnesia_table, repo_module))
      if unquote(required?.entity!), do: unquote(Macro.expand(default_implementation, __CALLER__).entity_txn_implementation(mnesia_table, repo_module))
      if unquote(required?.record), do: unquote(Macro.expand(default_implementation, __CALLER__).record_implementation(mnesia_table, repo_module))
      if unquote(required?.record!), do: unquote(Macro.expand(default_implementation, __CALLER__).record_txn_implementation(mnesia_table, repo_module))
      if unquote(required?.erp_imp), do: unquote(Macro.expand(default_implementation, __CALLER__).erp_imp(mnesia_table))
      if unquote(required?.as_record), do: unquote(Macro.expand(default_implementation, __CALLER__).as_record_implementation(mnesia_table, as_record_options))


      @before_compile unquote(__MODULE__)
    end # end quote
  end #end defmacro __using__(options)

  defmacro __before_compile__(_env) do
    quote do
      def has_permission(_ref, _permission, _context, _options), do: false
      def has_permission!(_ref, _permission, _context, _options), do: false
    end # end quote
  end # end defmacro __before_compile__(_env)

end #end defmodule
