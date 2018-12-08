# To avoid interlocking code a master defimpl should be defined for all tables and entities as follows.
alias Noizu.Scaffolding.Test.Fixture.FooV2Entity
alias Noizu.Database.Scaffolding.Test.Fixture.FooV2Table

defimpl Noizu.ERP, for: [FooV2Entity, FooV2Table] do
  defdelegate id(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate ref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate sref(o), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate entity!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
  defdelegate record!(o, options \\ nil), to: Noizu.Scaffolding.V2.ERPResolver
end