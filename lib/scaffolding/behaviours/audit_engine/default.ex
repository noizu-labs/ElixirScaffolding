#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.AuditEngine.Default do
  @behaviour Noizu.Scaffolding.AuditEngineBehaviour
  require Logger
  
  def audit(event, details, entity, context, note \\ nil) do
    Logger.info("AUDIT: #{inspect {event, details, entity, context, note}}")
  end

  def audit!(event, details, entity, context, note \\ nil) do
    audit(event, details, entity, context, note)
  end

end
