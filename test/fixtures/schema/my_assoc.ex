defmodule OneModel.Schema.MyAssoc do
  import Ecto.Changeset

  @type t :: %__MODULE__{
          __meta__: struct,
          id: integer | nil,
          one: String.t() | nil,
          two: String.t() | nil,
          three: integer() | nil,
          my_model_id: integer() | nil
        }

  use Ecto.Schema

  alias OneModel.Schema.MyModel

  schema "my_models" do
    field(:one, :string)
    field(:two, :string)
    field(:three, :integer)
    belongs_to(:my_model, MyModel)
  end

  @spec changeset(Ecto.Changeset.t() | t, map) :: Ecto.Changeset.t() | no_return
  def changeset(model, params \\ %{}) do
    cast(model, params, [:test, :my_model_id])
  end
end
