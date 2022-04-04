# To avoid interlocking code a master defimpl should be defined for all tables and entities as follows.
alias Noizu.Scaffolding.Test.Fixture.FooV1_1Entity
alias Noizu.Database.Scaffolding.Test.Fixture.FooV1_1Table

defimpl Noizu.ERP, for: [FooV1_1Entity, FooV1_1Table] do
 def id(%{__struct__: m} = ref), do: m.__erp__().id(ref)
 def ref(%{__struct__: m} = ref), do: m.__erp__().ref(ref)
 def sref(%{__struct__: m} = ref), do: m.__erp__().sref(ref)
 def record(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().record(ref, options)
 def record!(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().record!(ref, options)
 def entity(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().entity(ref, options)
 def entity!(%{__struct__: m} = ref, options \\ nil), do: m.__erp__().entity!(ref, options)
end