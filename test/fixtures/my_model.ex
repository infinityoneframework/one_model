defmodule OneModel.MyModel do
  # @type t :: OneModel.Schema.MyModel.t()
  # use OneModel, schema: OneModel.Schema.MyModel, repo: OneModel.TestRepo, t: true
  use OneModel, schema: OneModel.Schema.MyModel, repo: OneModel.TestRepo
end
