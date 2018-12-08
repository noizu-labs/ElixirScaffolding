#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------


use Amnesia
defdatabase Noizu.Database.Scaffolding.Test.Fixture do
  deftable FooTable, [:identifier, :second, :entity], type: :set, index: [] do
    @type t :: %FooTable{ identifier: any, second: any, entity: any}
  end # end table

  deftable FooV2Table, [:identifier, :second, :entity], type: :set, index: [] do
    @type t :: %FooV2Table{ identifier: any, second: any, entity: any}
    def erp_handler(), do: Noizu.Scaffolding.Test.Fixture.FooV2Entity
  end # end table

end # end defdatabase

