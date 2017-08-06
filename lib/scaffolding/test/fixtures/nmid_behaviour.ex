#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Author: Keith Brings <keith.brings@noizu.com>
# Copyright (C) 2017 La Crosse Technology LTD. All rights reserved.
#-------------------------------------------------------------------------------

if (Mix.env == :test) do
  defmodule Noizu.Scaffolding.Test.Fixture.NmidGenerator do
    def generate(_seq, _opts) do
      :os.system_time(:micro_seconds)
    end
    def generate!(seq, opts) do
      generate(seq, opts)
    end
  end
end
