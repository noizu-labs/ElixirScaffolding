#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2017 La Crosse Technology LTD. All rights reserved.
#-------------------------------------------------------------------------------
if (Mix.env == :test) do
  defmodule Noizu.Scaffolding.Test.Fixture.FooRepo do
    use Noizu.Scaffolding.RepoBehaviour,
      nmid_generator: Noizu.Scaffolding.Test.Fixture.NmidGenerator
  end
end
