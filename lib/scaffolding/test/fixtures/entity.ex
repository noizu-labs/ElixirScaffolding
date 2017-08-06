#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2017 La Crosse Technology LTD. All rights reserved.
#-------------------------------------------------------------------------------

if (Mix.env == :test) do
  defmodule Noizu.Scaffolding.Test.Fixture.FooEntity do
    use Noizu.Scaffolding.EntityBehaviour,
      sref_module: "foo-test",
      additional_mnesia_fields: :second
    @vsn(1.0)

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
  end
end
