defmodule Noizu.Scaffolding.InternalTask do
  alias Noizu.Scaffolding.CallingContext
  @default_level :internal
  @default_reasons(
    %{
      restricted: :restricted_call,
      internal: :internal_call,
      system: :system_call
    }
  )

  @type t :: %__MODULE__{
    level: :system | :restricted | :internal
  }
  defstruct [level: @default_level]

  #-----------------------------------------------------------------------------
  # Convienence
  #-----------------------------------------------------------------------------
  def calling_context(type \\ @default_level, env \\ nil, opts \\ %{})

  def calling_context(:internal, nil, _opts), do: CallingContext.new({:ref, __MODULE__, :internal}, {:ref, __MODULE__, :internal}, :generate, %{reason: @default_reasons[:internal]})
  def calling_context(:restricted, nil, _opts), do: CallingContext.new({:ref, __MODULE__, :restricted}, {:ref, __MODULE__, :restricted}, :generate, %{reason: @default_reasons[:restricted]})
  def calling_context(:system, nil, _opts), do: CallingContext.new({:ref, __MODULE__, :system}, {:ref, __MODULE__, :system}, :generate, %{reason: @default_reasons[:system]})
  def calling_context(%__MODULE__{level: type}, env, opts), do: calling_context(type, env, opts)
  def calling_context(type, %Plug.Conn{} = conn, %{} = opts) do
    token = opts[:token] || CallingContext.get_token(conn)
    opts = Map.put(opts, :reason, (opts[:reason] || CallingContext.get_reason(conn, @default_reasons[type])))
    CallingContext.new({:ref, __MODULE__, type}, {:ref, __MODULE__, type}, token, opts)
  end
  def calling_context(type, %CallingContext{} = outer_context, %{} = opts) do
    reason = case (opts[:reason] || outer_context.reason) do
      :not_specified -> @default_reasons[type]
      v -> v
    end
    opts = opts |> Map.put(:reason, reason) |> Map.put(:outer_context, outer_context)
    CallingContext.new({:ref, __MODULE__, type}, {:ref, __MODULE__, type}, (opts[:token] || outer_context.token), opts)
  end

  #-----------------------------------------------------------------------------
  # Behaviour Implementation
  #-----------------------------------------------------------------------------
  @behaviour Noizu.Scaffolding.EntityBehaviour
  def sref_module(), do: "internal-task"

  def id(nil), do: nil
  def id(identifier) do
    {:ref, __MODULE__, id} = ref(identifier)
    id
  end

  def ref(), do: ref(@default_level)
  def ref(level) when is_atom(level), do: {:ref, __MODULE__, level}
  def ref({:ref, __MODULE__, level}), do: ref(level)
  def ref(%__MODULE__{level: level}), do: ref(level)
  def ref(level) when is_bitstring(level) do
    case level do
      "ref.internal-task." <> level -> ref(level)
      "system" -> ref(:system)
      "internal" -> ref(:internal)
      "restricted" -> ref(:restricted)
    end
  end

  def sref(item) do
    {:ref, __MODULE__, type} = ref(item)
    "ref.#{sref_module()}.#{type}"
  end

  def entity(item, _options \\ nil) do
    {:ref, __MODULE__, type} = ref(item)
    %__MODULE__{level: type}
  end
  def entity!(item, _options \\ nil), do: entity(item)

  def record(item, _options \\ nil), do: entity(item)

  def record!(item, _options \\ nil), do: entity(item)

  def as_record(%__MODULE__{} = this), do: this

  defimpl Noizu.ERP, for: Noizu.Scaffolding.InternalTask do
    def ref(%Noizu.Scaffolding.InternalTask{level: level}), do: {:ref, Noizu.Scaffolding.InternalTask, level}
    def sref(%Noizu.Scaffolding.InternalTask{level: level}), do: "ref.internal-task.#{level}"
    def entity(item, _options \\ nil), do: item
    def entity!(item, _options \\ nil), do: item
    def record(item, _options \\ nil), do: item
    def record!(item, _options \\ nil), do: item
  end # end defimpl
end # end InternalTask
