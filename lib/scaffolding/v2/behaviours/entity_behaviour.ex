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



   @NOTE To avoid interlocking code a master defimpl should be defined for all tables and entities as follows.
   defimpl Noizu.ERP, for: [FooEntity, FooTable, ...] do
      defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
      defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
      defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
      defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
      defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
   end

  """
  #alias Noizu.ElixirCore.CallingContext
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

  @callback erp_handler() :: any
  @callback shallow(any) :: any
  @callback string_to_id(any) :: any
  @callback id_to_string(any) :: any
  @callback miss_cb(any, any) :: any
  @callback miss_cb!(any, any) :: any


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

  @callback as_record!(entity_obj, options :: Map.t) :: entity_record | error


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
    entity_table = case Keyword.get(options, :entity_table, :auto) do
      :auto -> Keyword.get(options, :mnesia_table, :auto)
      v -> v
    end

    poly_base = Keyword.get(options, :poly_base, :auto)
    poly_support = Keyword.get(options, :poly_support, :auto)



    as_record_options = Keyword.get(options, :as_record_options, Macro.escape(%{}))
    # Default Implementation Provider
    default_implementation = Keyword.get(options, :default_implementation, :auto)

    sm = Keyword.get(options, :sref_module, :auto)


    quote do
      import unquote(__MODULE__)
      @behaviour Noizu.Scaffolding.V2.EntityBehaviour

      @repo_module unquote(repo_module)
      @mnesia_table unquote(entity_table)

      @as_record_options unquote(as_record_options)
      @module __MODULE__

      @poly_base (case unquote(poly_base) do
        :auto -> @module
        v -> v
      end)

      @poly_support (case unquote(poly_support) do
        :auto -> :auto
        v when is_list(v) -> MapSet.new(v)
        v -> v
      end)

      @poly_type? ((@poly_base != @module) || (@poly_support != :auto) || false)


      @default_implementation (case unquote(default_implementation) do
        :auto ->
          if @poly_type? do
            Noizu.Scaffolding.V2.EntityBehaviourPolySupport
          else
            Noizu.Scaffolding.V2.EntityBehaviourDefault
          end
        v -> v
      end)

      @sref_prefix (case unquote(sm) do
        :auto ->
          if @poly_type? do
            cond do
              @module != @poly_base -> @poly_base.sref_prefix()
              true -> "ref.#{__MODULE__}."
            end
          else
            "ref.#{__MODULE__}."
          end
        v -> "ref.#{v}."
      end)


      @sref_module  (case unquote(sm) do
                       :auto ->
                         if @poly_type? do
                           cond do
                             @module != @poly_base -> @poly_base.sref_module()
                             true -> "#{__MODULE__}"
                           end
                         else
                           "#{__MODULE__}"
                         end
                       v -> "#{v}"
                     end)

      @expanded_repo @default_implementation.expand_repo(@poly_base == @module, @poly_base, @repo_module)
      @expanded_table @default_implementation.expand_table(@poly_base == @module, @poly_base, @mnesia_table)

      def sref_module(), do: @sref_module
      def sref_prefix(), do: @sref_prefix
      def poly_base(), do: @poly_base



      if (@module != @poly_base && @poly_support == :auto) do
        def poly_support() do
          @poly_base.poly_support()
        end
      else
        def poly_support() do
          @poly_support
        end
      end



      def poly_type?(), do: @poly_type?
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
      def compress(entity, options \\ %{}), do: compress(@module, entity, options)
      defdelegate compress(m, entity, options), to: @default_implementation

      #------------
      #
      #------------
      def expand(entity, options \\ %{}), do: expand(@module, entity, options)
      defdelegate expand(m, entity, options), to: @default_implementation

      #------------
      #
      #------------
      def string_to_id(identifier), do: string_to_id(@module, identifier)
      defdelegate  string_to_id(m, identifier), to: @default_implementation

      #------------
      #
      #------------
      def id_to_string(identifier), do: id_to_string(@module, identifier)
      defdelegate id_to_string(m, identifier), to: @default_implementation

      #------------
      #
      #------------
      def id(@sref_prefix <> identifier), do: id(@module, identifier)
      def id(ref), do: id(@module, ref)
      defdelegate id(m, ref), to: @default_implementation

      #------------
      #
      #------------
      def ref(ref), do: ref(@module, ref)
      defdelegate ref(m, ref), to: @default_implementation

      #------------
      #
      #------------
      def sref(ref), do: sref(@module, ref)
      defdelegate sref(m, ref), to: @default_implementation

      #------------
      #
      #------------
      def miss_cb(ref, options \\ %{}), do: miss_cb(@module, ref, options)
      defdelegate miss_cb(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def miss_cb!(ref, options \\ %{}), do: miss_cb!(@module, ref, options)
      defdelegate miss_cb!(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def entity(ref, options \\ %{}), do: entity(@module, ref, options)
      defdelegate entity(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def entity!(ref, options \\ %{}), do: entity!(@module, ref, options)
      defdelegate entity!(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def record(ref, options \\ %{}), do: record(@module, ref, options)
      defdelegate record(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def record!(ref, options \\ %{}), do: record!(@module, ref, options)
      defdelegate record!(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def as_record(ref, options \\ %{}), do: as_record(@module, ref, options)
      defdelegate as_record(m, ref, options), to: @default_implementation

      #------------
      #
      #------------
      def as_record!(ref, options \\ %{}), do: as_record!(@module, ref, options)
      defdelegate as_record!(m, ref, options), to: @default_implementation

      def has_permission(ref, permission, context, options \\ %{}), do: has_permission(@module, ref, permission, context, options)
      defdelegate has_permission(m, ref, permission, context, options), to: @default_implementation

      def has_permission!(ref, permission, context, options \\ %{}), do: has_permission!(@module, ref, permission, context, options)
      defdelegate has_permission!(m, ref, permission, context, options), to: @default_implementation

      defoverridable [
        sref_module: 0,
        sref_prefix: 0,
        poly_base: 0,
        poly_type?: 0,
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

        compress: 1,
        compress: 2,
        compress: 3,

        expand: 1,
        expand: 2,
        expand: 3,

        string_to_id: 1,
        string_to_id: 2,

        id_to_string: 1,
        id_to_string: 2,

        id: 1,
        id: 2,

        ref: 1,
        ref: 2,

        sref: 1,
        sref: 2,

        miss_cb: 1,
        miss_cb: 2,
        miss_cb: 3,
        miss_cb!: 1,
        miss_cb!: 2,
        miss_cb!: 3,

        entity: 1,
        entity: 2,
        entity: 3,
        entity!: 1,
        entity!: 2,
        entity!: 3,
        record: 1,
        record: 2,
        record: 3,
        record!: 1,
        record!: 2,
        record!: 3,
        as_record: 1,
        as_record: 2,
        as_record: 3,
        as_record!: 1,
        as_record!: 2,
        as_record!: 3,

        has_permission: 3,
        has_permission: 4,
        has_permission: 5,
        has_permission!: 3,
        has_permission!: 4,
        has_permission!: 5,
      ]

    end # end quote
  end #end defmacro __using__(options)

end #end defmodule
