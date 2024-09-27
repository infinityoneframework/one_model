defmodule OneModel.Schema.MyModel do
  import Ecto.Changeset

  @type t :: %__MODULE__{
          __meta__: struct,
          id: integer | nil,
          test: String.t() | nil,
          name: String.t() | nil,
          other: String.t() | nil
        }

  use Ecto.Schema

  alias OneModel.Schema.{MyAssoc, User}

  schema "my_models" do
    field(:test, :string)
    field(:name, :string)
    field(:other, :string)
    has_one(:my_assoc, MyAssoc)
    belongs_to(:user, User)
  end

  @spec changeset(Ecto.Changeset.t() | t, map) :: Ecto.Changeset.t() | no_return
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:id, :test, :user_id, :name, :other])
    |> validate_required([:test])
    |> validate_length(:test, min: 3)
  end
end
