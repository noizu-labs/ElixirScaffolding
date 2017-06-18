#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.Query.EntityRefFilteringBehaviour do

  defmacro __using__(options) do
    r = Keyword.get(options, :only, [:list, :create, :get, :update, :delete])
    only = %{
      list: Enum.member?(r, :list),
      get: Enum.member?(r, :get),
      update: Enum.member?(r, :update),
      delete: Enum.member?(r, :delete),
      create: Enum.member?(r, :create),
    }

    r = Keyword.get(options, :override, [])
    override = %{
      list: Enum.member?(r, :list),
      get: Enum.member?(r, :get),
      update: Enum.member?(r, :update),
      delete: Enum.member?(r, :delete),
      create: Enum.member?(r, :create),
    }
    mnesia_table = Keyword.get(options, :mnesia_table)

    constraint_field = Keyword.get(options, :constraint_field, :entity_ref)

    if mnesia_table == nil do
       raise "mnesia_table must be passed when calling RepoBehaviour"
    end

    quote do
      require Amnesia
      require Amnesia.Helper
      require Amnesia.Fragment
      import unquote(__MODULE__)
      use unquote(mnesia_table)
      @behaviour Noizu.Scaffolding.QueryBehaviour
      @mnesia_table unquote(mnesia_table)

      if (unquote(only.list) && !unquote(override.list)) do
        def list(%Noizu.Scaffolding.CallingContext{} = context, options) do
          if (options[:filter_caller]) do
            ref = context.caller
            @mnesia_table.where unquote(constraint_field) == ref
          else
            if (options[:filter_entity]) do
              ref = options[:filter_entity]
              @mnesia_table.where unquote(constraint_field) == ref
            else
              @mnesia_table.where 1 == 1
            end
          end
        end
      end # end conditional include

      if (unquote(only.get) && !unquote(override.get)) do
        def get(identifier, %Noizu.Scaffolding.CallingContext{} = context, options) do
          record = @mnesia_table.read(identifier)
          if (options[:filter_caller]) do
            ref = context.caller
            if (record.unquote(constraint_field) == ref), do: record, else: raise "Not linked to caller"
          else
            if (options[:filter_entity]) do
              ref = options[:filter_entity]
              if (record.unquote(constraint_field) == ref), do: record, else: raise "Not linked to filter_entity"
            else
              record
            end
          end
        end
      end # end conditional include

      if (unquote(only.create) && !unquote(override.create)) do
        def create(record, %Noizu.Scaffolding.CallingContext{} = context, options) do
          if (options[:filter_caller]) do
            ref = context.caller
            if (record.unquote(constraint_field) == ref) , do: @mnesia_table.write(record), else: raise "Not linked to caller"
          else
            if (options[:filter_entity]) do
              ref = options[:filter_entity]
              if (record.unquote(constraint_field) == ref) , do: @mnesia_table.write(record), else: raise "Not linked to filter_entity"
            else
              @mnesia_table.write(record)
            end
          end
        end
      end # end conditional include

      if (unquote(only.update) && !unquote(override.update)) do
        def update(record, %Noizu.Scaffolding.CallingContext{} = context, options) do
          if (options[:filter_caller]) do
            ref = context.caller
            record2 = @mnesia_table.read(record.identifier)
            if (record2.unquote(constraint_field) == ref), do: @mnesia_table.write(record), else: raise "Not linked to caller"
          else
            if (options[:filter_entity]) do
              ref = options[:filter_entity]
              record2 = @mnesia_table.read(record.identifier)
              if (record2.unquote(constraint_field) == ref), do: @mnesia_table.write(record), else: raise "Not linked to filter_entity"
            else
              @mnesia_table.write(record)
            end
          end
        end
      end # end conditional include

      if (unquote(only.delete) && !unquote(override.delete)) do
        def delete(identifier, %Noizu.Scaffolding.CallingContext{} = context, options) do
          if (options[:filter_caller]) do
            ref = context.caller
            record = @mnesia_table.read(identifier)
            if (record.unquote(constraint_field) == ref), do: @mnesia_table.delete(identifier), else: raise "Not linked to caller"
          else
            if (options[:filter_entity]) do
              ref = options[:filter_entity]
              record = @mnesia_table.read(identifier)
              if (record.unquote(constraint_field) == ref), do: @mnesia_table.delete(identifier), else: raise "Not linked to filter_entity"
            else
              @mnesia_table.delete(identifier)
            end
          end
        end
      end # end conditional include
    end # end quote
  end # end using macro
end # end module
