#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2017 La Crosse Technology LTD. All rights reserved.
#-------------------------------------------------------------------------------
if (Mix.env == :test) do
  use Amnesia
  defdatabase Noizu.Database.Scaffolding.Test.Fixture do
    deftable FooTable, [:identifier, :second, :entity], type: :set, index: [] do
      @type t :: %FooTable{ identifier: any, second: any, entity: any}
    end # end table
  end # end defdatabase
end
