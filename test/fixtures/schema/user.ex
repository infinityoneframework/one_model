defmodule OneModel.Schema.User do
  import Ecto.Changeset

  @type t :: %__MODULE__{
          __meta__: struct,
          id: integer | nil,
          name: String.t() | nil,
          username: String.t() | nil
        }

  use Ecto.Schema

  alias OneModel.Schema.MyModel

  schema "users" do
    field(:name, :string)
    field(:username, :string)
    has_many(:my_models, MyModel)
  end

  @spec changeset(Ecto.Changeset.t() | t, map) :: Ecto.Changeset.t() | no_return
  def changeset(model, params \\ %{}) do
    cast(model, params, [:id, :name, :username])
  end
end
