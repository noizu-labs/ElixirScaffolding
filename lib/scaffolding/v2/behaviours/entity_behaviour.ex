#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.V2.EntityBehaviour do
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
  @callback as_record(entity_obj, options :: Map.t) :: entity_record | error

  @doc """
    Returns the string used for preparing sref format strings. E.g. a `User` struct might use the string ``"user"`` as it's sref_module resulting in
    sref strings like `ref.user.1234`.
  """
  @callback sref_module() :: String.t

  @doc """
  get entitie's repo module
  """
  @callback repo() :: atom


  @doc """
  Compress entity, default options
  """
  @callback compress(entity :: any) :: any

  @doc """
  Compress entity
  """
  @callback compress(entity :: any, options :: Map.t) :: any

  @doc """
  Expand entity, default options
  """
  @callback expand(entity :: any) :: any

  @doc """
  Expand entity
  """
  @callback expand(entity :: any, options :: Map.t) :: any

  #-----------------------------------------------------------------------------
  # Defines
  #-----------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  # Using Implementation
  #-----------------------------------------------------------------------------
  defmacro __using__(options) do
    # Repo module (entity/record implementation), Module name with "Repo" appeneded if :auto
    repo_module = Keyword.get(options, :repo_module, :auto)
    mnesia_table = Keyword.get(options, :mnesia_table, :auto)
    as_record_options = Keyword.get(options, :as_record_options, Macro.escape(%{}))
    # Default Implementation Provider
    default_implementation = Keyword.get(options, :default_implementation, Noizu.Scaffolding.V2.EntityBehaviourDefault)
    sm = Keyword.get(options, :sref_module, "unsupported")
    sref_prefix = "ref." <> sm <> "."

    quote do
      import unquote(__MODULE__)
      @behaviour Noizu.Scaffolding.EntityBehaviour

      @default_implementation unquote(default_implementation)
      @repo_module unquote(repo_module)
      @expanded_repo @default_implementation.expand_repo(__MODULE__, @repo_module)
      @sref_module unquote(sm)
      @mnesia_table unquote(mnesia_table)
      @expanded_table @default_implementation.expand_table(__MODULE__, @mnesia_table)
      @sref_prefix unquote(sref_prefix)
      @as_record_options unquote(as_record_options)

      @module __MODULE__

      def sref_module(), do: @sref_module
      def sref_prefix(), do: @sref_prefix


      def repo(), do: @expanded_repo
      def table(), do: @expanded_table
      def erp_handler(), do: @module

      def _int_entity?(), do: true
      def _int_as_record_options(), do: @as_record_options
      def _int_expanded_repo(), do: @expanded_repo
      def _int_repo_module(), do: @repo_module
      def _int_implementation(), do: @default_implementation
      def _int_empty_record(), do: %@expanded_table{}

      #-------------------------------------------------------------------------
      # Default Implementation from default_implementation behaviour
      #-------------------------------------------------------------------------

      #------------
      #
      #------------
      def shallow(identifier), do: %@module{identifier: identifier}

      #------------
      #
      #------------
      def compress(entity, options \\ %{}), do: compress_implementation(@module, entity, options)
      defdelegate compress_implementation(m, entity, options), to: @default_implementation

      #------------
      #
      #------------
      def expand(entity, options \\ %{}), do: expand_implementation(@module, entity, options)
      defdelegate expand_implementation(m, entity, options), to: @default_implementation

      #------------
      #
      #------------
      def id(@sref_prefix <> identifier), do: id_implementation(@module, identifier)
      def id(ref), do: id_implementation(@module, ref)
      defdelegate id_implementation(m, ref), to: @default_implementation

      #------------
      #
      #------------
      def ref(ref), do: ref_implementation(@module, ref)
      defdelegate ref_implementation(m, ref), to: @default_implementation

      #------------
      #
      #------------
      def sref(ref), do: sref_implementation(@module, ref)
      defdelegate sref_implementation(m, ref), to: @default_implementation

      #------------
      #
      #------------
      def miss_cb(ref, options \\ %{}), do: miss_cb_implementation(@module, ref, options)
      defdelegate miss_cb_implementation(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def entity(ref, options \\ %{}), do: entity_implementation(@module, ref, options)
      defdelegate entity_implementation(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def entity!(ref, options \\ %{}), do: entity_txn_implementation(@module, ref, options)
      defdelegate entity_txn_implementation(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def record(ref, options \\ %{}), do: record_implementation(@module, ref, options)
      defdelegate record_implementation(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def record!(ref, options \\ %{}), do: record_txn_implementation(@module, ref, options)
      defdelegate record_txn_implementation(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def as_record(ref, options \\ %{}), do: as_record_implementation(@module, ref, options)
      defdelegate as_record_implementation(m, ref, options), to: @default_implementation

      def has_permission(ref, permission, context, options \\ %{}), do: has_permission_implementation(@module, ref, permission, context, options)
      defdelegate has_permission_implementation(m, ref, permission, context, options), to: @default_implementation

      def has_permission!(ref, permission, context, options \\ %{}), do: has_permission_txn_implementation(@module, ref, permission, context, options)
      defdelegate has_permission_txn_implementation(m, ref, permission, context, options), to: @default_implementation

      # To avoid interlocking code a master defimpl should be defined for all tables and entities as follows.
      #defimpl Noizu.ERP, for: [FooEntity, FooTable, ...] do
      #  defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
      #  defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
      #  defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
      #  defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      #  defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      #  defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      #  defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      #end

      defoverridable [
        sref_module: 0,
        sref_prefix: 0,

        repo: 0,
        table: 0,
        erp_handler: 0,
        _int_entity?: 0,
        _int_as_record_options: 0,
        _int_expanded_repo: 0,
        _int_repo_module: 0,
        _int_implementation: 0,
        _int_empty_record: 0,

        shallow: 1,
        compress: 2,
        expand: 2,

        id: 1,
        ref: 1,
        sref: 1,
        miss_cb: 2,
        entity: 2,
        entity!: 2,
        record: 2,
        record!: 2,
        as_record: 2,

        has_permission: 4,
        has_permission!: 4,
      ]

    end # end quote
  end #end defmacro __using__(options)

end #end defmodule
