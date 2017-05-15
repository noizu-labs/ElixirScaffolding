#-------------------------------------------------------------------------------
# Author: Keith Brings
# Copyright (C) 2017 Noizu Labs, Inc. All rights reserved.
#-------------------------------------------------------------------------------

defmodule Noizu.Scaffolding.EntityBehaviour do
  @moduledoc("""
  This Behaviour provides some callbacks needed for the Noizu.ERP (EntityReferenceProtocol) to work smoothly.
  """)
  @type nmid :: integer | atom | String.t | tuple
  @type entity_obj :: any
  @type entity_record :: any
  @type entity_tuple_reference :: {:ref, module, nmid}
  @type entity_string_reference :: String.t
  @type details :: any
  @type error :: {:error, details}
  @type options :: Map.t | nil

  @callback ref(entity_tuple_reference | entity_obj) :: entity_tuple_reference | error
  @callback sref(entity_tuple_reference | entity_obj) :: entity_string_reference | error
  @callback entity(entity_tuple_reference | entity_obj, options) :: entity_obj | error
  @callback entity!(entity_tuple_reference | entity_obj, options) :: entity_obj | error
  @callback record(entity_tuple_reference | entity_obj, options) :: entity_record | error
  @callback record!(entity_tuple_reference | entity_obj, options) :: entity_record | error
end
