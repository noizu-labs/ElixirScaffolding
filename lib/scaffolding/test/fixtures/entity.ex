#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2018 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

if (Mix.env == :test) do
  defmodule Noizu.Scaffolding.Test.Fixture.FooEntity do
    @vsn (1.0)

    #-----------------------------------------------------------------------------
    # Struct & Types
    #-----------------------------------------------------------------------------
    @type t :: %__MODULE__{
      identifier: Types.appengine_id,
      second: any,
      content: any,
      vsn: Types.vsn
    }

    defstruct [
        identifier: nil,
        second: :apple,
        content: :test,
        vsn: @vsn
    ]

    use Noizu.Scaffolding.EntityBehaviour,
        sref_module: "foo-test",
        additional_mnesia_fields: :second
  end
end
