defmodule OneModelTest do
  use ExUnit.Case

  import Mox

  alias OneModel.{MyAssoc, MyModel}
  alias OneModel.TestRepoMock

  doctest OneModel

  setup :verify_on_exit!

  test "list" do
    expect(TestRepoMock, :all, fn _ -> [] end)
    assert MyModel.list() == []
  end

  test "create" do
    expect(TestRepoMock, :insert, fn changeset ->
      assert changeset.valid?
      assert changeset.changes == %{test: "abc"}
      {:ok, Map.merge(changeset.data, changeset.changes)}
    end)

    {:ok, model} = MyModel.create(%{test: "abc"})
    assert model.test == "abc"

    expect(TestRepoMock, :insert, fn changeset ->
      {:error, changeset}
    end)

    {:error, changeset} = MyModel.create(%{})

    refute changeset.valid?
    assert changeset.errors == [test: {"can't be blank", [validation: :required]}]
  end

  test "create!" do
    expect(TestRepoMock, :insert!, fn changeset ->
      assert changeset.valid?
      assert changeset.changes == %{test: "abc"}
      Map.merge(changeset.data, changeset.changes)
    end)

    model = MyModel.create!(%{test: "abc"})
    assert model.test == "abc"

    expect(TestRepoMock, :insert!, fn changeset ->
      refute changeset.valid?
      nil
    end)

    refute MyModel.create!(%{})
  end

  test "update" do
    model = MyModel.new(test: "abc")

    expect(TestRepoMock, :update, fn changeset ->
      {:ok, Map.merge(changeset.data, changeset.changes)}
    end)

    {:ok, model} = MyModel.update(model, %{test: "another"})
    assert model.test == "another"

    expect(TestRepoMock, :update, fn changeset ->
      {:error, changeset}
    end)

    {:error, changeset} = MyModel.update(model, %{test: "ab"})

    refute changeset.valid?

    assert changeset.errors == [
             test:
               {"should be at least %{count} character(s)",
                [count: 3, validation: :length, min: 3]}
           ]
  end

  test "update!" do
    model = MyModel.new(test: "abc")

    expect(TestRepoMock, :update!, fn changeset ->
      Map.merge(changeset.data, changeset.changes)
    end)

    model = MyModel.update!(model, %{test: "another"})
    assert model.test == "another"

    expect(TestRepoMock, :update!, fn changeset ->
      refute changeset.valid?
      nil
    end)

    refute MyModel.update!(model, %{test: "ab"})
  end

  test "delete/1" do
    model = MyModel.new(test: "abc")

    expect(TestRepoMock, :delete, fn schema -> {:ok, schema} end)
    {:ok, _schema} = MyModel.delete(model)

    expect(TestRepoMock, :delete, fn changeset -> {:ok, changeset.data} end)
    {:ok, _schema} = MyModel.delete(MyModel.change(model, %{}))
  end

  test "delete!/1" do
    model = MyModel.new(test: "abc")

    expect(TestRepoMock, :delete!, fn schema -> schema end)
    assert MyModel.delete!(model)

    expect(TestRepoMock, :delete!, fn changeset -> changeset.data end)
    assert MyModel.delete!(MyModel.change(model, %{}))

    expect(TestRepoMock, :delete!, fn changeset ->
      refute changeset.valid?
      nil
    end)

    changeset = model |> MyModel.change(%{}) |> Map.put(:valid?, false)
    refute MyModel.delete!(changeset)
  end

  describe "query_sort_and_paginate" do
    test "empty fields" do
      item = MyModel.new(id: 1, test: "testing", my_assoc: nil, user: nil)

      expect(TestRepoMock, :all, fn _arg -> [item] end)

      expect(TestRepoMock, :one, fn _arg -> 1 end)

      fields = Jason.encode!(%{})

      {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

      assert item == %{id: 1, test: "testing", my_assoc: nil, user: nil}
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 1)
    end

    test "include fields" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, fn _ -> [item] end)
      expect(TestRepoMock, :one, fn _arg -> 2 end)

      fields = Jason.encode!(%{id: 1, test: 1, my_assoc: 1})

      {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

      assert item == %{id: 1, test: "testing", my_assoc: %{id: 2, one: "1", two: "2"}}
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 2)
    end

    test "include fields 2" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, fn _ -> [item] end)
      expect(TestRepoMock, :one, fn _arg -> 2 end)

      fields = Jason.encode!(%{id: 1, test: 1, user: 1})

      {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

      assert item == %{id: 1, test: "testing", user: nil}
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 2)
    end

    test "exclude fields" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, 1, fn _ -> [item] end)
      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      fields = Jason.encode!(%{id: 0, my_assoc: 0, user: 0})

      {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

      assert item == %{test: "testing"}
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 2)

      # 2nd test
      expect(TestRepoMock, :all, 1, fn _ -> [item] end)
      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      fields = Jason.encode!(%{id: 0, my_assoc: 0})

      {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

      assert item == %{test: "testing", user: nil}
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 2)
    end

    test "exclude fields 2" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, 1, fn _ -> [item] end)
      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      fields = Jason.encode!(%{id: 0, user: 0})

      {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

      assert item == %{test: "testing", my_assoc: %{id: 2, one: "1", two: "2"}}
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 2)
    end
  end
end
