# To avoid interlocking code a master defimpl should be defined for all tables and entities as follows.
alias Noizu.Scaffolding.Test.Fixture.FooV2Entity
alias Noizu.Database.Scaffolding.Test.Fixture.FooV2Table

defimpl Noizu.ERP, for: [FooV2Entity, FooV2Table] do
 def id(o), do: Noizu.Scaffolding.V2.ERPResolver.id(o)
 def ref(o), do: Noizu.Scaffolding.V2.ERPResolver.ref(o)
 def sref(o), do: Noizu.Scaffolding.V2.ERPResolver.sref(o)
 def entity(o, options \\ nil), do: Noizu.Scaffolding.V2.ERPResolver.entity(o, options)
 def entity!(o, options \\ nil), do: Noizu.Scaffolding.V2.ERPResolver.entity!(o, options)
 def record(o, options \\ nil), do: Noizu.Scaffolding.V2.ERPResolver.record(o, options)
 def record!(o, options \\ nil), do: Noizu.Scaffolding.V2.ERPResolver.record!(o, options)
end

