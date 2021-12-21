defmodule OneModel.MyAssoc do
  use OneModel,
    schema: OneModel.Schema.MyAssoc,
    repo: OneModel.TestRepoMock
end
