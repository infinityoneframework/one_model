defmodule OneModel.TestRepo do
  @callback all(queryable :: Ecto.Query.t()) :: [Ecto.Schema.t()] | no_return()
  @callback all(queryable :: Ecto.Query.t(), opts :: Keyword.t()) ::
              [Ecto.Schema.t()] | no_return()
  @callback one(queryable :: Ecto.Query.t()) :: Ecto.Schema.t() | nil

  @callback insert(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback insert!(Ecto.Changeset.t()) :: Ecto.Schema.t() | no_return()
  @callback update(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback update!(Ecto.Changeset.t()) :: Ecto.Schema.t() | no_return()
  @callback delete(Ecto.Changeset.t() | Ecto.Schema.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback delete!(Ecto.Changeset.t() | Ecto.Schema.t()) :: Ecto.Schema.t() | no_return()

  use Ecto.Repo,
    otp_app: :one_model,
    adapter: Ecto.Adapters.Postgres

  # def all(_opts \\ []), do: []
  # def one(_, _ \\ nil), do: nil
  # def one!(_, _ \\ nil), do: nil
  # def get(_, _ \\ nil, _ \\ nil), do: nil
  # def get!(_, _ \\ nil, _ \\ nil), do: nil
  # def get_by(_, _ \\ nil, _ \\ nil), do: nil
  # def get_by!(_, _ \\ nil, _ \\ nil), do: nil
  # def insert(_, _ \\ nil), do: {:ok, %{}}
  # def insert!(_, _ \\ nil), do: %{}
  # def update(_, _ \\ nil), do: {:ok, %{}}
  # def update!(_, _ \\ nil), do: %{}
  # def delete(_, _ \\ nil), do: %{}
  # def delete!(_, _ \\ nil), do: %{}
  # def delete_all(_, _ \\ nil), do: nil
  # def delete_all!(_, _ \\ nil), do: nil

  # def preload(_, _), do: []
end
