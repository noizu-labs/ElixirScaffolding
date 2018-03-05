#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

if (Mix.env == :test) do
  use Amnesia
  defdatabase Noizu.Database.Scaffolding.Test.Fixture do
    deftable FooTable, [:identifier, :second, :entity], type: :set, index: [] do
      @type t :: %FooTable{ identifier: any, second: any, entity: any}
    end # end table
  end # end defdatabase
end
