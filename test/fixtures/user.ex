defmodule OneModel.User do
  use OneModel,
    schema: OneModel.Schema.User,
    repo: OneModel.TestRepoMock,
    default_fields: ~w(id name username)a,
    default_assoc_fields: [
      :my_models,
      my_assoc: ~w(id one two)a
    ]
end
