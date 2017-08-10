#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.QueryStrategy.Default do
  @behaviour Noizu.Scaffolding.QueryBehaviour  
  alias Noizu.Scaffolding.CallingContext
  alias Amnesia.Table, as: T
  #alias Amnesia.Table.Selection, as: S
  require Exquisite


  def list(mnesia_table, %CallingContext{} = _context, _options) do
    a = for index <- 1..Enum.count(mnesia_table.attributes()) do
      String.to_atom("$#{index}")
    end
    t = List.to_tuple([mnesia_table] ++ a)
    spec = [{t, [{:==, true, true}], [:"$_"]}]
    raw = T.select(mnesia_table, spec)
    %Amnesia.Table.Select{raw| coerce: mnesia_table}
  end

  def get(identifier, mnesia_table,  %CallingContext{} = _context, _options) do
    mnesia_table.read(identifier)
  end

  def update(entity, mnesia_table,  %CallingContext{} = _context, _options) do
    mnesia_table.write(entity)
  end

  def create(entity, mnesia_table,  %CallingContext{} = _context, _options) do
    mnesia_table.write(entity)
  end

  def delete(identifier, mnesia_table,  %CallingContext{} = _context, _options) do
    mnesia_table.delete(identifier)
  end

end
