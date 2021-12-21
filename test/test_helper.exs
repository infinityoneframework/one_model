ExUnit.start()

Mox.defmock(OneModel.TestRepoMock, for: OneModel.TestRepo)

Application.put_env(:one_model, :repo, OneModel.TestRepoMock)
