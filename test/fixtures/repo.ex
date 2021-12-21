defmodule OneModel.TestRepo do
  @callback all(queryable :: Ecto.Query.t()) :: [Ecto.Schema.t()] | no_return()
  @callback all(queryable :: Ecto.Query.t(), opts :: Keyword.t()) ::
              [Ecto.Schema.t()] | no_return()
  @callback one(queryable :: Ecto.Query.t()) :: Ecto.Schema.t() | nil
  @callback one!(queryable :: Ecto.Query.t()) :: Ecto.Schema.t() | no_return()

  @callback insert(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback insert!(Ecto.Changeset.t()) :: Ecto.Schema.t() | no_return()
  @callback update(Ecto.Changeset.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback update!(Ecto.Changeset.t()) :: Ecto.Schema.t() | no_return()
  @callback delete(Ecto.Changeset.t() | Ecto.Schema.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  @callback delete!(Ecto.Changeset.t() | Ecto.Schema.t()) :: Ecto.Schema.t() | no_return()
  @callback get(atom, integer()) :: Ecto.Schema.t() | nil
  @callback get!(atom, integer()) :: Ecto.Schema.t() | no_return()
  @callback get_by(atom, keyword()) :: Ecto.Schema.t() | nil
  @callback get_by!(atom, keyword()) :: Ecto.Schema.t() | no_return()
  @callback preload(any, any) :: any

  use Ecto.Repo,
    otp_app: :one_model,
    adapter: Ecto.Adapters.Postgres
end
