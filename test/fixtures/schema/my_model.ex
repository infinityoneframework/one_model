defmodule OneModel.Schema.MyModel do
  import Ecto.Changeset

  @type t :: %__MODULE__{
    __meta__: struct,
    id: integer | nil,
    test: String.t() | nil,
  }

  use Ecto.Schema

  schema "my_models" do
    field :test, :string
  end

  @spec changeset(Ecto.Changeset.t | t, map) :: Ecto.Changeset.t | no_return
  def changeset(model, params \\ %{}) do
    cast(model, params, [:test])
  end
end
