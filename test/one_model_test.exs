defmodule OneModelTest do
  use ExUnit.Case

  import Mox
  import ExUnit.CaptureLog

  alias OneModel.{MyAssoc, MyModel, User}
  alias OneModel.Schema.MyModel, as: MyModelSchema
  alias OneModel.TestRepoMock

  require Ecto.Query, as: Query
  require Logger
  require Integer

  doctest OneModel

  setup :verify_on_exit!

  def setup_data(_) do
    my_models = for i <- 1..3, do: MyModel.new(id: i, test: "test #{i}")
    users = for i <- 1..3, do: User.new(id: i, name: "User #{i}", username: "user#{i}")
    {:ok, users: users, my_models: my_models}
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
    expect(TestRepoMock, :insert, fn changeset ->
      assert changeset.valid?
      assert changeset.changes == %{test: "abc"}
      {:ok, Map.merge(changeset.data, changeset.changes)}
    end)

    model = MyModel.create!(%{test: "abc"})
    assert model.test == "abc"

    expect(TestRepoMock, :insert, fn changeset ->
      refute changeset.valid?
      {:error, changeset}
    end)

    assert_raise(Ecto.InvalidChangesetError, fn -> MyModel.create!(%{}) end)
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
                [count: 3, validation: :length, kind: :min, type: :string]}
           ]
  end

  test "update!" do
    model = MyModel.new(test: "abc")

    expect(TestRepoMock, :update, fn changeset ->
      {:ok, Map.merge(changeset.data, changeset.changes)}
    end)

    model = MyModel.update!(model, %{test: "another"})
    assert model.test == "another"

    expect(TestRepoMock, :update, fn changeset ->
      refute changeset.valid?
      {:error, changeset}
    end)

    assert_raise(Ecto.InvalidChangesetError, fn -> MyModel.update!(model, %{test: "ab"}) end)
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

    expect(TestRepoMock, :delete, fn schema -> {:ok, schema} end)
    assert MyModel.delete!(model)

    expect(TestRepoMock, :delete, fn changeset -> {:ok, changeset.data} end)
    assert MyModel.delete!(MyModel.change(model, %{}))

    expect(TestRepoMock, :delete, fn changeset ->
      refute changeset.valid?
      {:error, changeset}
    end)

    changeset = model |> MyModel.change(%{}) |> Map.put(:valid?, false)
    assert_raise(Ecto.InvalidChangesetError, fn -> MyModel.delete!(changeset) end)
  end

  describe "access" do
    setup [:setup_data]

    test "get/1", %{my_models: [model | _] = models} do
      expect(TestRepoMock, :get, fn MyModelSchema, id -> Enum.find(models, &(&1.id == id)) end)
      assert MyModel.get(model.id) == model
    end

    test "get/2", %{my_models: [model | _]} do
      expect(TestRepoMock, :one, fn %{from: from, wheres: [%{expr: expr}]} ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:==, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}, {:^, [], [0]}]}
        model
      end)

      assert MyModel.get(model.id, preload: [:user]) == model
    end

    test "get!/1", %{my_models: [model | _] = models} do
      expect(TestRepoMock, :get!, fn MyModelSchema, id -> Enum.find(models, &(&1.id == id)) end)
      assert MyModel.get!(model.id) == model
    end

    test "get!/2", %{my_models: [model | _]} do
      expect(TestRepoMock, :one!, fn %{from: from, wheres: [%{expr: expr}]} ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:==, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}, {:^, [], [0]}]}
        model
      end)

      assert MyModel.get!(model.id, preload: [:user]) == model
    end

    test "get_by", %{my_models: [_, model2 | _] = models} do
      expect(TestRepoMock, :one, fn %{from: from, wheres: [%{expr: expr, params: params}]} ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:==, [], [{{:., [], [{:&, [], [0]}, :test]}, [], []}, {:^, [], [0]}]}
        assert params == [{model2.test, {0, :test}}]

        Enum.find(models, &(&1.test == model2.test))
      end)

      assert MyModel.get_by(test: model2.test) == model2
    end

    test "get_by!/1", %{my_models: [_, model2 | _] = models} do
      expect(TestRepoMock, :one!, fn %{from: from, wheres: [%{expr: expr, params: params}]} ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:==, [], [{{:., [], [{:&, [], [0]}, :test]}, [], []}, {:^, [], [0]}]}
        assert params == [{model2.test, {0, :test}}]

        Enum.find(models, &(&1.test == model2.test))
      end)

      assert MyModel.get_by!(test: model2.test) == model2
    end

    test "list/0", %{my_models: list} do
      expect(TestRepoMock, :all, fn _ -> list end)
      assert MyModel.list() == list
    end

    test "list_by/1", %{my_models: [_, model2 | _] = models} do
      expect(TestRepoMock, :all, fn %{from: from, wheres: [%{expr: expr, params: params}]} ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:==, [], [{{:., [], [{:&, [], [0]}, :test]}, [], []}, {:^, [], [0]}]}
        assert params == [{model2.test, {0, :test}}]

        Enum.find(models, &(&1.test == model2.test))
      end)

      assert MyModel.list_by(test: model2.test) == model2

      expect(TestRepoMock, :all, fn %{
                                      from: from,
                                      preloads: preloads,
                                      wheres: [%{expr: expr, params: params}]
                                    } ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:==, [], [{{:., [], [{:&, [], [0]}, :test]}, [], []}, {:^, [], [0]}]}
        assert params == [{model2.test, {0, :test}}]
        assert preloads == [:user]

        Enum.find(models, &(&1.test == model2.test))
      end)

      assert MyModel.list_by(test: model2.test, preload: [:user]) == model2
    end

    test "count/0" do
      expect(TestRepoMock, :one, fn %{from: from, select: %{expr: expr}} ->
        assert from.source == {"my_models", MyModelSchema}
        assert expr == {:count, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}]}
        1
      end)

      assert MyModel.count() == 1
    end

    test "count_by/1", %{my_models: [_, model2 | _]} do
      expect(TestRepoMock, :one, fn %{wheres: wheres, from: from, select: %{expr: expr}} ->
        assert expr == {:count, [], [{{:., [], [{:&, [], [0]}, :id]}, [], []}]}

        assert wheres |> Enum.map(&Map.take(&1, ~w(expr op params)a)) == [
                 %{
                   expr: {:==, [], [{{:., [], [{:&, [], [0]}, :test]}, [], []}, {:^, [], [0]}]},
                   op: :and,
                   params: [{"test 2", {0, :test}}]
                 },
                 %{
                   expr:
                     {:==, [], [{{:., [], [{:&, [], [0]}, :preload]}, [], []}, {:^, [], [0]}]},
                   op: :and,
                   params: [{[:user], {0, :preload}}]
                 }
               ]

        assert from.source == {"my_models", MyModelSchema}
        1
      end)

      assert MyModel.count_by(test: model2.test, preload: [:user]) == 1
    end

    test "preload_schema/2", %{my_models: [model | _]} do
      expect(TestRepoMock, :preload, fn ^model, [:user] -> model end)
      assert MyModel.preload_schema(model, [:user]) == model
    end

    test "all/1", %{my_models: models} do
      expect(TestRepoMock, :all, fn MyModelSchema ->
        models
      end)

      assert MyModel.all(MyModelSchema) == models
    end

    test "one/1", %{my_models: [model | _] = models} do
      expect(TestRepoMock, :one, fn %{from: from, limit: limit} ->
        assert from.source == {"my_models", MyModelSchema}
        assert limit.expr == 1
        hd(models)
      end)

      assert MyModelSchema |> Query.limit(1) |> MyModel.one() == model
    end
  end

  describe "mutations" do
    setup [:setup_data]

    test "change/1 valid" do
      changeset = MyModel.change(%{test: "abcd"})
      assert changeset.valid?
      assert changeset.changes == %{test: "abcd"}
    end

    test "change/1 invalid" do
      assert capture_log(fn ->
               changeset = MyModel.change(%{test: "a"})
               refute changeset.valid?

               assert changeset.errors == [
                        {:test,
                         {"should be at least %{count} character(s)",
                          [count: 3, validation: :length, kind: :min, type: :string]}}
                      ]
             end) == ""
    end

    test "change/2 valid", %{my_models: [model | _]} do
      changeset = MyModel.change(model, %{test: "testing"})
      assert changeset.valid?
      assert changeset.changes == %{test: "testing"}
    end

    test "change/2 invalid", %{my_models: [model | _]} do
      changeset = MyModel.change(model, %{test: "x"})
      refute changeset.valid?

      assert changeset.errors == [
               {:test,
                {"should be at least %{count} character(s)",
                 [count: 3, validation: :length, kind: :min, type: :string]}}
             ]
    end
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

    test "include fields invalid" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, fn _ -> [item] end)
      expect(TestRepoMock, :one, fn _arg -> 2 end)

      fields = Jason.encode!(%{id: 1, test: 1, my_assoc: 1}) <> "}"

      assert capture_log(fn ->
               {[item], paging} = MyModel.query_sort_and_paginate(%{"fields" => fields}, id: 1)

               assert item == %{
                        id: 1,
                        test: "testing",
                        my_assoc: %{id: 2, one: "1", two: "2"},
                        user: nil
                      }

               assert Enum.sort(paging) == Enum.sort(offset: 0, count: 1, total: 2)
             end) == ""
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

    test "offset, count" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, 1, fn _ -> [item] end)
      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      params = %{offset: 1, count: 2}

      {[item], paging} = MyModel.query_sort_and_paginate(params, test: "test")

      assert item == %{id: 1, my_assoc: %{id: 2, one: "1", two: "2"}, test: "testing", user: nil}
      assert Enum.sort(paging) == Enum.sort(offset: 1, count: 1, total: 2)
    end

    test "count 0" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, 1, fn _ -> [item, item] end)
      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      params = %{count: 0}

      {items, paging} = MyModel.query_sort_and_paginate(params, test: "test")

      assert length(items) == 2
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)
    end

    test "limit 0" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      expect(TestRepoMock, :all, 1, fn _ -> [item, item] end)
      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      params = %{limit: 0}

      {items, paging} = MyModel.query_sort_and_paginate(params, test: "test")

      assert length(items) == 2
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)
    end

    test "sort" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      item2 = Map.merge(item, %{id: 2, test: "two"})

      expect(TestRepoMock, :all, fn %{order_bys: [%{expr: expr}]} ->
        assert expr == [asc: {{:., [], [{:&, [], [0]}, :id]}, [], []}]
        [item, item2]
      end)

      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      params = %{sort: %{id: :asc}}

      {items, paging} = MyModel.query_sort_and_paginate(params)
      assert Enum.map(items, & &1.id) == [1, 2]
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)
      params = %{sort: %{id: :desc}}

      expect(TestRepoMock, :all, fn %{order_bys: [%{expr: expr}]} ->
        assert expr == [desc: {{:., [], [{:&, [], [0]}, :id]}, [], []}]
        [item2, item]
      end)

      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      {items, paging} = MyModel.query_sort_and_paginate(params)
      assert Enum.map(items, & &1.id) == [2, 1]
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)
    end

    test "sort json" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      item2 = Map.merge(item, %{id: 2, test: "two"})

      expect(TestRepoMock, :all, fn %{order_bys: [%{expr: expr}]} ->
        assert expr == [asc: {{:., [], [{:&, [], [0]}, :id]}, [], []}]
        [item, item2]
      end)

      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      params = %{sort: Jason.encode!(%{id: 1})}

      {items, paging} = MyModel.query_sort_and_paginate(params)
      assert Enum.map(items, & &1.id) == [1, 2]
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)

      params = %{sort: Jason.encode!(%{id: -1})}

      expect(TestRepoMock, :all, fn %{order_bys: [%{expr: expr}]} ->
        assert expr == [desc: {{:., [], [{:&, [], [0]}, :id]}, [], []}]
        [item2, item]
      end)

      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      {items, paging} = MyModel.query_sort_and_paginate(params)
      assert Enum.map(items, & &1.id) == [2, 1]
      assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)
    end

    test "sort json invalid" do
      item =
        MyModel.new(
          id: 1,
          test: "testing",
          my_assoc: MyAssoc.new(id: 2, one: "1", two: "2", three: 3),
          user: nil
        )

      item2 = Map.merge(item, %{id: 2, test: "two"})

      expect(TestRepoMock, :all, fn %{order_bys: [%{expr: expr}]} ->
        assert expr == [asc: {{:., [], [{:&, [], [0]}, :id]}, [], []}]
        [item, item2]
      end)

      expect(TestRepoMock, :one, 1, fn _arg -> 2 end)

      params = %{sort: Jason.encode!(%{id: 0})}

      assert capture_log(fn ->
          {items, paging} = MyModel.query_sort_and_paginate(params)
          assert Enum.map(items, & &1.id) == [1, 2]
          assert Enum.sort(paging) == Enum.sort(offset: 0, count: 2, total: 2)
        end) =~ "invalid order field: 0"
    end
  end

  describe "add_query_fields/2" do
    test "$regex" do
      query_fields = %{"test" => %{"$regex" => "t"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " REGEXP ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]},
               op: :and,
               params: [{"t", :any}]
             }
    end

    test "$eq" do
      query_fields = %{"test" => %{"$eq" => "test"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :any}],
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " = ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]}
             }
    end

    test "$ne" do
      query_fields = %{"test" => %{"$ne" => "test"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :any}],
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " != ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]}
             }
    end

    test "$lt" do
      query_fields = %{"test" => %{"$lt" => "test"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :any}],
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " < ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]}
             }
    end

    test "$lte" do
      query_fields = %{"test" => %{"$lte" => "test"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :any}],
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " <= ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]}
             }
    end

    test "$gt" do
      query_fields = %{"test" => %{"$gt" => "test"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :any}],
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " > ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]}
             }
    end

    test "$gte" do
      query_fields = %{"test" => %{"$gte" => "test"}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :any}],
               expr:
                 {:fragment, [],
                  [
                    raw: "",
                    expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                    raw: " >= ",
                    expr: {:^, [], [0]},
                    raw: ""
                  ]}
             }
    end

    test "$in" do
      query_fields = %{"test" => %{"$in" => ["t", "tt"]}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{["t", "tt"], {:in, {0, :test}}}],
               expr: {
                 :in,
                 [],
                 [
                   {{:., [], [{:&, [], [0]}, :test]}, [], []},
                   {:^, [], [0]}
                 ]
               }
             }
    end

    test "$nin" do
      query_fields = %{"test" => %{"$nin" => ["t", "tt"]}}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{["t", "tt"], {:in, {0, :test}}}],
               expr: {
                 :not,
                 [],
                 [
                   {
                     :in,
                     [],
                     [
                       {{:., [], [{:&, [], [0]}, :test]}, [], []},
                       {:^, [], [0]}
                     ]
                   }
                 ]
               }
             }
    end

    test "value" do
      query_fields = %{"test" => "test"}

      %{from: from, wheres: [where]} =
        Map.from_struct(OneModel.add_query_fields(MyModelSchema, %{query: query_fields}))

      assert from.source == {"my_models", MyModelSchema}

      assert Map.take(where, ~w(expr op params)a) == %{
               op: :and,
               params: [{"test", :string}],
               expr:
                 {:like, [],
                  [
                    {:fragment, [],
                     [
                       raw: "LOWER(",
                       expr: {{:., [], [{:&, [], [0]}, :test]}, [], []},
                       raw: ")"
                     ]},
                    {:^, [], [0]}
                  ]}
             }
    end

    test "no query" do
      assert OneModel.add_query_fields(MyModelSchema, %{}) == MyModelSchema
    end
  end

  describe "query_params/1" do
    test "binary key" do
      params = %{"query" => %{"test" => %{"$gt" => "test"}}}
      assert OneModel.query_params(params) == %{query: %{"test" => %{"$gt" => "test"}}}
    end

    test "binary key, json payload" do
      params = %{"query" => Jason.encode!(%{"test" => %{"$gt" => "test"}})}
      assert OneModel.query_params(params) == %{query: %{"test" => %{"$gt" => "test"}}}
    end

    test "binary key, invalid json payload" do
      params = %{"query" => "{" <> Jason.encode!(%{"test" => %{"$gt" => "test"}})}

      assert capture_log(fn ->
               assert OneModel.query_params(params) == %{}
             end) =~ "error: {:error, %Jason.DecodeError"
    end
  end
end
