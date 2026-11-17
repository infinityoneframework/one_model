defmodule OneModel.MyModel do
  use OneModel,
    schema: OneModel.Schema.MyModel,
    repo: OneModel.TestRepo,
    default_fields: ~w(id test)a,
    default_assoc_fields: [
      :user,
      my_assoc: ~w(id one two)a
    ]
end
