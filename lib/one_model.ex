defmodule OneModel do
  @moduledoc """
  Model abstraction for InfinityOne.

  Provides an alternative solution to the fat Phoenix Context model, allowing
  the user to create a one to one context mapping between a model (singular context)
  and its schema.

  ## Examples

  For example, you may organize your models/schemas like:

      lib/my_app/models
        blog.ex
        post.ex
        schema
          blog_schema.ex
          post_schema.exe

  And have the following files:

      # post.ex
      defmodule MyApp.Post do
        use InfinityOne.Model, schema: MyApp.Post.Schema

        @doc ~s(
          Example to show overriding default behaviour
        )
        def delete(schema_or_changeset) do
          schema_or_changeset
          |> pre_process_delete()
          |> super()
        end

        defp pre_process_delete(schema) do
          # do something with schema before delete
          schema
        end
      end

      # schema/post_schema.ex
      defmodule MyApp.Post.Schema do
        use Ecto.Schema
        import Ecto.Changeset

        schema "posts" do
          field :title, :string
          field :body, :string
          belongs_to :blog, MyApp.Blog.Schema
        end

        def changeset(struct, params) do
          struct
          |> cast(params, [:tile, :body, :blog_id])
          |> validate_required([:title, :body, :blog_id])
        end
      end

      MyApp.Post.create(%{title: "My Title", body: "Some Body", blog_id: blog.id})
      {:ok, %MyApp.Post.Schema{id: "...", title: "...", ...}}

      MyApp.Post.list_by(blog_id: blog.id, preload: [:blog])
      [%MyApp.Post.Schema{blog: %MyApp.Blog.Schema{...}, ...}, ...]

  The above example provides the following functions in the `MyApp.Post`:

  * delete/1
  * delete!/1
  * update/1
  * update/2
  * update!/1
  * update!/2
  * create/1
  * create!/1
  * get_by/1
  * get_by!/1
  * get/2
  * get!/2
  * list/0
  * change/2
  * change/1
  * delete_all/0
  * preload_schema/2
  * count/0
  * count_by/1
  """
  import Ecto.Query
  require Logger

  defmacro __using__(opts) do
    quote do
      opts = unquote(opts)
      @repo opts[:repo] || InfinityOne.Repo
      @schema opts[:schema] || raise(":schema option required")
      @default_fields opts[:default_fields] || @schema.__schema__(:fields)
      @default_assoc_fields opts[:default_assoc_fields] || @schema.__schema__(:associations)
      @default_limit opts[:default_limit] || 50

      @type id :: integer | String.t()

      import Ecto.Query, except: [update: 2], warn: false

      @doc """
      Create a default #{@schema} struct.
      """
      @spec new() :: Struct.t()
      def new, do: %@schema{}

      @doc """
      Create a #{@schema} with the provided options.
      """
      @spec new(Keyword.t()) :: Struct.t()
      def new(opts), do: struct(new(), opts)

      @doc """
      Return the schema module.
      """
      @spec schema() :: Module.t()
      def schema, do: @schema

      @doc """
      Returns an `%Ecto.Changeset{}` for tracking #{@schema} changes.
      """
      @spec change(Struct.t(), Keyword.t()) :: Ecto.Changeset.t()
      def change(%@schema{} = schema, attrs) do
        @schema.changeset(schema, attrs)
      end

      @doc """
      Returns an `%Ecto.Changeset{}` for tracking #{@schema} changes.
      """
      @spec change(Struct.t()) :: Ecto.Changeset.t()
      def change(%@schema{} = schema) do
        @schema.changeset(schema)
      end

      @spec change(Keyword.t()) :: Ecto.Changeset.t()
      def change(attrs) when is_map(attrs) or is_list(attrs) do
        @schema.changeset(%@schema{}, attrs)
      end

      @doc """
      Get a list of #{@schema}'s.

      ## Options'

      * `preload: list`
      """
      @spec list(Keword.t()) :: [Struct.t()]
      def list(opts \\ []) do
        if preload = opts[:preload] do
          @schema
          |> preload(^preload)
          |> order_by(asc: :inserted_at)
          |> @repo.all
        else
          @repo.all(@schema)
        end
      end

      @doc """
      Get a list of #{@schema},s given a list of field value pairs.

      ## Preload

      Pass a list of preloads with the `:preload` key.

      ## Examples

          #{@schema}.list_by field1: value1, field2: field2, preload: [:association]
      """
      @spec list_by(Keyword.t()) :: List.t()
      def list_by(opts) do
        opts
        |> list_by_query()
        |> order_by(asc: :inserted_at)
        |> @repo.all()
      end

      def list_by_query(params, opts \\ []) do
        {preload, params} = Keyword.pop(params, :preload, [])
        preload = if opts[:preload] == false or preload == [], do: false, else: preload

        params
        |> Enum.reduce(@schema, fn {k, v}, query ->
          where(query, [b], field(b, ^k) == ^v)
        end)
        |> do_preload(preload)
      end

      defp do_preload(query, false), do: query
      defp do_preload(query, []), do: query
      defp do_preload(query, preload), do: preload(query, ^preload)

      @doc """
      Get a single #{@schema}.

      ## Preload

      Pass a list of preloads with the `:preload` key.
      """
      @spec get(id, Keyword.t()) :: Struct.t()
      def get(id, opts \\ []) do
        if preload = opts[:preload] do
          @repo.one(from(s in @schema, where: s.id == ^id, preload: ^preload))
        else
          @repo.get(@schema, id, opts)
        end
      end

      @spec get!(id, Keyword.t()) :: Struct.t()
      def get!(id, opts \\ []) do
        if preload = opts[:preload] do
          @repo.one!(from(s in @schema, where: s.id == ^id, preload: ^preload))
        else
          @repo.get!(@schema, id, opts)
        end
      end

      @spec get_by(Keyword.t()) :: Struct.t()
      def get_by(opts) do
        if preload = opts[:preload] do
          # TODO: Fix this with a single query
          @schema
          |> @repo.get_by(Keyword.delete(opts, :preload))
          |> @repo.preload(preload)
        else
          @repo.get_by(@schema, opts)
        end
      end

      @spec get_by!(Keyword.t()) :: Struct.t()
      def get_by!(opts) do
        if preload = opts[:preload] do
          @schema
          |> @repo.get_by(Keyword.delete(opts, :preload))
          |> @repo.preload(preload)
        else
          @repo.get_by!(@schema, opts)
        end
      end

      @spec create(Ecto.Changeset.t() | Keyword.t() | Map.t()) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def create(changeset_or_attrs \\ %{})

      def create(%Ecto.Changeset{} = changeset) do
        @repo.insert(changeset)
      end

      def create(attrs) do
        create(change(attrs))
      end

      def create!(changeset_or_attrs \\ %{})

      @spec create!(Ecto.Changeset.t()) :: Struct.t() | no_return
      def create!(%Ecto.Changeset{} = changeset) do
        @repo.insert!(changeset)
      end

      @spec create!(Keyword.t()) :: Struct.t() | no_return
      def create!(attrs) do
        create!(change(attrs))
      end

      @spec update(Ecto.Changeset.t()) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def update(%Ecto.Changeset{} = changeset) do
        @repo.update(changeset)
      end

      @spec update(Struct.t(), Keyword.t()) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def update(%@schema{} = schema, attrs) do
        schema
        |> change(attrs)
        |> update
      end

      @spec update!(Ecto.Changeset.t()) :: Struct.t() | no_return
      def update!(%Ecto.Changeset{} = changeset) do
        @repo.update!(changeset)
      end

      @spec update!(Struct.t(), Keyword.t()) :: Struct.t() | no_return
      def update!(%@schema{} = schema, attrs) do
        schema
        |> change(attrs)
        |> update!
      end

      @spec delete(Struct.t()) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def delete(%@schema{} = schema) do
        delete(change(schema))
      end

      @doc """
      Delete the #{@schema} given by an `Ecto.Changeset`.
      """
      @spec delete(Ecto.Changeset.t()) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def delete(%Ecto.Changeset{} = changeset) do
        @repo.delete(changeset)
      end

      @doc """
      Delete the #{@schema} given by an id.
      """
      @spec delete(id) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def delete(id) do
        delete(get(id))
      end

      @doc """
      Delete the #{@schema} given a the struct, or raise an exception.
      """
      @spec delete!(Struct.t()) :: Struct.t() | no_return
      def delete!(%@schema{} = schema) do
        delete!(change(schema))
      end

      @doc """
      Delete the #{@schema} given a changeset, or raise an exception.
      """
      @spec delete!(Ecto.Changeset.t()) ::
              {:ok, Struct.t()}
              | {:error, Ecto.Changeset.t()}
      def delete!(%Ecto.Changeset{} = changeset) do
        @repo.delete!(changeset)
      end

      @doc """
      Delete the given #{@schema} by id, or raise an exception.
      """
      @spec delete!(id) :: Struct.t() | no_return
      def delete!(id) do
        delete!(get(id))
      end

      @doc """
      Delete all #{@schema}'s.
      """
      # @spec delete_all() :: any
      def delete_all do
        @repo.delete_all(@schema)
      end

      @doc """
      Get the first #{@schema} ordered by creation date
      """
      @spec first() :: Struct.t() | nil
      def first do
        @schema
        |> order_by(asc: :inserted_at)
        |> first
        |> @repo.one
      end

      @doc """
      Get the last #{@schema} ordered by creation date
      """
      @spec last() :: Struct.t() | nil
      def last do
        @schema
        |> order_by(asc: :inserted_at)
        |> last
        |> @repo.one
      end

      @doc """
      Get the number of records in the #{@schema} schema.
      """
      @spec count() :: integer
      def count do
        @repo.one(from(s in @schema, select: count(s.id)))
      end

      @doc """
      Count the number of records for the #{@schema} schema.

      Counts the number of records matching the provided clauses.

      ## Example

          MyModel.count_by(published: true, expired: false)
      """
      @spec count_by(Keyword.t() | map()) :: integer
      def count_by(clauses) do
        clauses
        |> Enum.reduce(@schema, fn {k, v}, query ->
          where(query, [b], field(b, ^k) == ^v)
        end)
        |> select([b], count(b.id))
        |> @repo.one
      end

      @doc """
      Preload a #{@schema}.
      """
      def preload_schema(schema, preload) do
        @repo.preload(schema, preload)
      end

      def all(query) do
        @repo.all(query)
      end

      def one(query) do
        @repo.one(query)
      end

      @doc """
      Fetch records given the selection parameters supported by many API requests.
      """

      def query_sort_and_paginate(params, opts \\ []) do
        defaults = %{
          fields: @default_fields,
          assoc_fields: @default_assoc_fields,
          limit: @default_limit
        }

        OneModel.query_sort_and_paginate(__MODULE__, params, defaults, opts)
      end

      def paging_stats(list, params, opts \\ []) do
        OneModel.paging_stats(params, fn ->
          [count: length(list), total: get_query_count(params, opts)]
        end)
      end

      def get_query_count(params, opts \\ []) do
        OneModel.get_query_count(__MODULE__, params, opts)
      end

      def query_fields(params) do
        defaults = %{
          fields: @default_fields,
          assoc_fields: @default_assoc_fields,
          limit: @default_limit
        }

        OneModel.query_fields(params, defaults)
      end

      def fields_list(params) do
        defaults = %{
          fields: @default_fields,
          assoc_fields: @default_assoc_fields,
          limit: @default_limit
        }

        params
        |> OneModel.query_fields(defaults)
        |> OneModel.fields_list(defaults)
      end

      defoverridable delete: 1,
                     delete!: 1,
                     update: 1,
                     update: 2,
                     update!: 1,
                     update!: 2,
                     create: 1,
                     create!: 1,
                     get_by: 1,
                     get_by!: 1,
                     get: 2,
                     get!: 2,
                     list: 0,
                     change: 2,
                     change: 1,
                     delete_all: 0,
                     preload_schema: 2,
                     count: 0,
                     count_by: 1,
                     query_sort_and_paginate: 2,
                     list_by_query: 1,
                     all: 1,
                     one: 1,
                     query_fields: 1,
                     fields_list: 1,
                     get_query_count: 1,
                     paging_stats: 2
    end
  end

  def query_sort_and_paginate(model, params, defaults, opts \\ []) do
    query_params = query_params(params)

    query_fields = query_fields(params, defaults)

    list =
      opts
      |> model.list_by_query()
      |> add_limit(query_params, defaults)
      |> add_offset(query_params)
      |> add_sort(query_params)
      |> add_query_fields(query_params)
      |> model.all()
      |> build_fields_list(query_fields, defaults)

    {list, model.paging_stats(list, params, opts)}
  end

  defp add_limit(query, %{limit: count} = opts, defaults) do
    add_limit(query, opts |> Map.delete(:limit) |> Map.put(:count, count), defaults)
  end

  defp add_limit(query, %{count: 0}, _) do
    limit(query, 10_000_000)
  end

  defp add_limit(query, %{count: count}, _) do
    limit(query, ^count)
  end

  defp add_limit(query, _, %{limit: count}) do
    limit(query, ^count)
  end

  defp add_offset(query, %{offset: offset}) do
    offset(query, ^offset)
  end

  defp add_offset(query, _) do
    query
  end

  defp add_sort(query, %{sort: sort}) do
    Enum.reduce(sort, query, fn {name, order}, acc ->
      order_by(acc, [c], [{^order, field(c, ^name)}])
    end)
  end

  defp add_sort(query, _) do
    query
  end

  def add_query_fields(query, %{query: query_fields}) do
    Enum.reduce(query_fields, query, fn
      {field, %{"$regex" => regex}}, acc ->
        field = String.to_existing_atom(field)
        where(acc, [c], fragment("? REGEXP ?", field(c, ^field), ^regex))

      {field, %{} = map}, acc ->
        field = String.to_existing_atom(field)

        Enum.reduce(map, acc, fn {key, value}, acc ->
          build_query_filters(acc, field, value, key)
        end)

      {field, value}, acc when is_binary(field) ->
        field = String.to_existing_atom(field)
        where(acc, [c], like(fragment("LOWER(?)", field(c, ^field)), ^value))
    end)
  end

  def add_query_fields(query, _) do
    query
  end

  defp build_query_filters(builder, field, value, "$gt"),
    do: where(builder, [c], fragment("? > ?", field(c, ^field), ^value))

  defp build_query_filters(builder, field, value, "$gte"),
    do: where(builder, [c], fragment("? >= ?", field(c, ^field), ^value))

  defp build_query_filters(builder, field, value, "$lt"),
    do: where(builder, [c], fragment("? < ?", field(c, ^field), ^value))

  defp build_query_filters(builder, field, value, "$lte"),
    do: where(builder, [c], fragment("? <= ?", field(c, ^field), ^value))

  defp build_query_filters(builder, field, value, "$ne"),
    do: where(builder, [c], fragment("? != ?", field(c, ^field), ^value))

  defp build_query_filters(builder, field, value, "$eq"),
    do: where(builder, [c], fragment("? = ?", field(c, ^field), ^value))

  defp build_query_filters(builder, field, value, "$in"),
    do: where(builder, [c], field(c, ^field) in ^value)

  defp build_query_filters(builder, field, value, "$nin"),
    do: where(builder, [c], not (field(c, ^field) in ^value))

  # TODO: This function currently processes the list fetched from the database
  #       and filters the fields given. This is not optimized. It would be
  #       much better to do this with a select on the query before the data
  #       is fetched from the database. However, I was unable to figure out
  #       how to do this using the current 2.1 version of Ecto. Ecto 2.2 has a
  #       :select_merge option but upgrading to 2.2 is not as simple as updating
  #       the dependency which I tried.
  defp build_fields_list(list, %{include: include}, defaults) when include != [] do
    incl = include -- defaults.assoc_fields
    select_fields(list, incl, include -- incl)
  end

  defp build_fields_list(list, %{exclude: exclude}, defaults) do
    excl = exclude -- defaults.assoc_fields
    select_fields(list, defaults.fields -- excl, defaults.assoc_fields -- exclude)
  end

  defp build_fields_list(list, _, _) do
    list
  end

  defp select_fields(list, fields, _assoc_fields) do
    Enum.map(list, fn item ->
      for f <- fields, into: %{}, do: {f, Map.get(item, f)}
    end)
  end

  @doc """
  Get the list of fields and assoc_fields given query params.
  """
  def fields_list(%{include: include}, defaults) when include != [] do
    incl = include -- defaults.assoc_fields
    {incl, include -- incl}
  end

  def fields_list(%{exclude: exclude}, defaults) do
    excl = exclude -- defaults.assoc_fields
    {defaults.fields -- excl, defaults.assoc_fields -- exclude}
  end

  def fields_list(_, defaults) do
    {defaults.fields, defaults.assoc_fields}
  end

  def paging_stats(params, fun) do
    query_params = query_params(params)
    offset = query_params[:offset] || 0

    [{:offset, to_integer(offset || 0)}] ++ fun.()
  end

  def get_query_count(model, params, opts \\ []) do
    query_params = query_params(params)

    opts
    |> model.list_by_query(preload: false)
    |> add_query_fields(query_params)
    |> select([m], count(m.id))
    |> model.one()
  end

  @doc """
  Parses the url's query parameters and builds the state map.

  Creates a map with defaults based on the url's query parameters. Looks at
  each of:

  - count
  - offset
  - sort json object
  - query json object
  """
  def query_params(params) do
    %{}
    |> count_params(params)
    |> offset_params(params)
    |> sort_params(params)
    |> query_params(params)
  end

  defp query_params(params, %{"query" => query}) do
    query_params(params, %{query: query})
  end

  defp query_params(params, %{query: query}) when is_binary(query) do
    case Jason.decode(query) do
      {:ok, map} ->
        Map.put(params, :query, map)

      error ->
        Logger.warn("error: #{inspect(error)}")
        params
    end
  end

  defp query_params(params, %{query: query}) when is_map(query) do
    Map.put(params, :query, query)
  end

  defp query_params(params, _) do
    params
  end

  defp count_params(params, %{"count" => count}) do
    count_params(params, %{count: count})
  end

  defp count_params(params, %{count: count}) do
    Map.put(params, :count, to_integer(count))
  end

  defp count_params(params, _) do
    params
  end

  defp offset_params(params, %{"offset" => offset}) do
    offset_params(params, %{offset: offset})
  end

  defp offset_params(params, %{offset: offset}) do
    Map.put(params, :offset, to_integer(offset))
  end

  defp offset_params(params, _) do
    params
  end

  defp sort_params(params, %{"sort" => sort}) do
    sort_params(params, %{sort: sort})
  end

  defp sort_params(params, %{sort: sort = %{}}) do
    Map.put(params, :sort, sort)
  end

  defp sort_params(params, %{sort: sort}) when is_binary(sort) do
    case sort |> String.replace("'", "\"") |> Jason.decode() do
      {:ok, map} ->
        Map.put(params, :sort, for({key, val} <- map, into: %{}, do: {to_atom(key), order(val)}))

      _ ->
        params
    end
  end

  defp sort_params(params, _) do
    params
  end

  defp order(1), do: :asc
  defp order(-1), do: :desc

  defp order(other) do
    Logger.warn("invalid order field: #{other}")
    :asc
  end

  @doc """
  Build the query fields from the params hash.

  Builds a map containing the included and excluded fields passed in the URL.
  Expects the provided fields entry to be a JSON object.

  Returns:

  - `%{exclude: []}` if nothing is provided. this is the default behaviour.
  - `%{exclude: [], include: [:field1, :field2]}` when include fields are given
  - `%{exclude: [:field1, :field2], include: []}` if exclude fields are given

  """
  def query_fields(%{"fields" => fields}, defaults) do
    case Jason.decode(fields) do
      {:ok, fields} ->
        %{include: incl_exclude(fields, 1), exclude: incl_exclude(fields, 0)}

      _ ->
        query_fields(nil, defaults)
    end
  end

  def query_fields(_, _defaults) do
    %{}
  end

  # def query_fields(%{fields: fields} = params) when is_map(fields) do
  #   default_fields = params[:default_fields] || params["default_fields"] || []
  #   %{fields: default_fields ++ (incl_exclude(fields, 1) -- incl_exclude(fields, 0))}
  # end

  # def query_fields(params) do
  #   %{fields: params[:default_fields] || params["default_fields"] || []}
  # end

  defp incl_exclude(fields, which) do
    fields
    |> Enum.filter(fn {_name, val} -> val == which end)
    |> Enum.map(fn {name, _} -> to_existing_atom(name) end)
  end

  defp to_existing_atom(value) when is_binary(value) do
    String.to_existing_atom(value)
  end

  defp to_existing_atom(value) when is_atom(value) do
    value
  end

  @doc """
  Safe conversion of string to integer.

  Allows nil, integers, and stings to be converted with the following behavior:

  * integer - pass the value unchanged.
  * binary - Attempt to convert it. Raises an exception if its not a valid integer
  * nil - Return 0

  ## Examples

      iex> OneModel.to_integer("123")
      123
      iex> OneModel.to_integer(nil)
      0
      iex> OneModel.to_integer(123)
      123
  """
  def to_integer(nil), do: 0
  def to_integer(int) when is_integer(int), do: int

  def to_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      {value, ""} ->
        value

      {value, other} ->
        Logger.warn("inaccurate parse #{inspect({value, other})} for '#{string}'")
        value

      _ ->
        Logger.warn("invalid integer string '#{string}'")
        0
    end
  end

  @doc """
  Safe conversion to existing atom.

  Allows binary and atoms to be passed. If an atom, returns it unchanged

  ## Examples

      iex> OneModel.to_atom(:test)
      :test
      iex> OneModel.to_atom("test")
      :test
  """
  def to_atom(value) when is_atom(value), do: value
  def to_atom(value) when is_binary(value), do: String.to_existing_atom(value)
end
