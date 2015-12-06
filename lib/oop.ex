defmodule OOP do
  import Kernel, except: [def: 2, def: 4, defp: 2, defp: 4]

  defmacro __using__(_) do
    quote do
      import OOP, only: [class: 2]
    end
  end

  defmacro class(name, do: block) do
    quote do
      defmodule unquote(name) do
        @make_init true

        import Kernel, except: [def: 2, def: 4, defp: 2, defp: 4]
        import OOP, only: [def: 2, defp: 2, attr_reader: 1, attr_writer: 1, attr_accessor: 1, attr: 1]

        unquote block

        if @make_init do
          def initialize, do: nil
        end

        Kernel.def inspect({ name, pid }) do
          pid = :erlang.pid_to_list(pid.to_pid)
          "#<#{String.replace(to_string(name), ~r/^Elixir\./, "")}:#{Enum.slice(pid, 1, Enum.count(pid) - 2)}>"
        end

        Kernel.def inspect(_, obj), do: obj.inspect

        Kernel.def to_s(obj), do: obj.inspect

        defoverridable [inspect: 2, inspect: 1, to_s: 1]
      end

      defimpl Inspect, for: unquote(name) do
        def inspect(obj, opts) do
          obj.inspect(opts)
        end
      end

      defimpl String.Chars, for: unquote(name) do
        def to_string(obj), do: obj.to_s
      end
    end
  end

  defmacro attr_reader({ name, _, _ }) do
    defreader!(name)
  end

  defmacro attr_reader(name) when is_atom(name) do
    defreader!(name)
  end

  defmacro attr_reader(names) when is_list(names) do
    readers = Enum.map names, fn
      { name, _, _ } -> defreader!(name)
      name when is_atom(name) -> defreader!(name)
    end

    quote do: unquote readers
  end

  defmacro attr_writer({ name, _, _ }) do
    defwriter!(name)
  end

  defmacro attr_writer(name) when is_atom(name) do
    defwriter!(name)
  end

  defmacro attr_writer(names) when is_list(names) do
    writers = Enum.map names, fn
      { name, _, _ } -> defwriter!(name)
      name when is_atom(name) -> defwriter!(name)
    end

    quote do: unquote writers
  end

  defmacro attr_accessor({ name, _, _ }) do
    defaccessor!(name)
  end

  defmacro attr_accessor(name) when is_atom(name) do
    defaccessor!(name)
  end

  defmacro attr_accessor(names) when is_list(names) do
    accessors = Enum.reverse Enum.reduce names, [], fn
      { name, _, _ }, a ->
        [defwriter!(name), defreader!(name)|a]
      name, a when is_atom(name) ->
        [defwriter!(name), defreader!(name)|a]
    end

    quote do: unquote accessors
  end

  defmacro attr({ name, _, _ }) do
    defaccessor!(name)
  end

  defmacro attr(name) when is_atom(name) do
    defaccessor!(name)
  end

  defmacro attr(names) when is_list(names) do
    accessors = Enum.reverse Enum.reduce names, [], fn
      { name, _, _ }, a ->
        [defwriter!(name), defreader!(name)|a]
      name, a when is_atom(name) ->
        [defwriter!(name), defreader!(name)|a]
    end

    quote do: unquote accessors
  end

  defmacro def({ :when, _, [{ name, _, params }|guards] }, do: block) do
    defmethod!(name, params, guards, block)
  end

  defmacro def({ name, _, nil }, do: block) do
    defmethod!(name, block)
  end

  defmacro def({ name, _, params }, do: block) when is_list(params) do
    defmethod!(name, params, block)
  end

  defmacro def({ name, _, param }, do: block) do
    defmethod!(name, [param], block)
  end

  defmacro defp({ :when, _, [{ name, _, params }|guards] }, do: block) do
    defmethodp!(name, params, guards, block)
  end

  defmacro defp({ name, _, nil }, do: block) do
    defmethodp!(name, block)
  end

  defmacro defp({ name, _, params }, do: block) when is_list(params) do
    defmethodp!(name, params, block)
  end

  defmacro defp({ name, _, param }, do: block) do
    defmethodp!(name, [param], block)
  end

  defmacro @({ attr, _, nil }) do
    quote do
      import Kernel, except: [@: 1, send: 2]
      import Process.Managed, only: [send: 2]

      {_, pid} = self
      send pid, { Kernel.self, unquote(attr) }
      rpid = pid.to_pid
      receive do
        { ^rpid, value } -> value
      end
    end
  end

  defmacro @({ attr, _, [code] }) do
    quote do
      import Kernel, except: [@: 1, send: 2]
      import Process.Managed, only: [send: 2]

      {_, pid} = self
      send pid, { Kernel.self, { unquote(attr), unquote(code) } }
      rpid = pid.to_pid
      receive do
        { ^rpid, val } -> val
      end
    end
  end

  Kernel.defp defmethod!(:initialize, params, guards, block) do
    quote do
      @make_init false

      Kernel.def new(unquote_splicing(params))
        when unquote_splicing(guards) do
          import Kernel, except: [@: 1, send: 2]
          import Process.Managed, only: [send: 2]
          import OOP, only: [@: 1]
          self = { __MODULE__, OOP.new_server }
          unquote transform block
          self
      end
    end
  end

  Kernel.defp defmethod!(name, params, guards, block) do
    quote do
      Kernel.def unquote(name)(unquote_splicing(params), { __MODULE__, { Process.Managed, _, _ } } = self)
        when unquote_splicing(guards) do
          import Kernel, except: [@: 1, send: 2]
          import Process.Managed, only: [send: 2]
          import OOP, only: [@: 1]
          unquote transform block
      end
    end
  end

  Kernel.defp defmethod!(:initialize, params, block) do
    quote do
      @make_init false

      Kernel.def new(unquote_splicing(params)) do
        import Kernel, except: [@: 1, send: 2]
        import Process.Managed, only: [send: 2]
        import OOP, only: [@: 1]
        self = { __MODULE__, OOP.new_server }
        unquote transform block
        self
      end
    end
  end

  Kernel.defp defmethod!(name, params, block) do
    quote do
      Kernel.def unquote(name)(unquote_splicing(params), { __MODULE__, { Process.Managed, _, _ } } = self) do
        import Kernel, except: [@: 1, send: 2]
        import Process.Managed, only: [send: 2]
        import OOP, only: [@: 1]
        unquote transform block
      end
    end
  end

  Kernel.defp defmethod!(:initialize, block) do
    quote do
      @make_init false

      Kernel.def new() do
        import Kernel, except: [@: 1, send: 2]
        import Process.Managed, only: [send: 2]
        import OOP, only: [@: 1]
        self = { __MODULE__, OOP.new_server }
        unquote transform block
        self
      end
    end
  end

  Kernel.defp defmethod!(name, block) do
    quote do
      Kernel.def unquote(name)({ __MODULE__, { Process.Managed, _, _ } } = self) do
        import Kernel, except: [@: 1, send: 2]
        import Process.Managed, only: [send: 2]
        import OOP, only: [@: 1]
        unquote transform block
      end
    end
  end

  Kernel.defp defmethodp!(name, params, guards, block) do
    quote do
      Kernel.defp unquote(name)(unquote_splicing(params), { __MODULE__, { Process.Managed, _, _ } } = self)
        when (unquote_splicing(guards)) do
          import Kernel, except: [@: 1, send: 2]
          import Process.Managed, only: [send: 2]
          import OOP, only: [@: 1]
          unquote transform block
      end
    end
  end

  Kernel.defp defmethodp!(name, params, block) do
    quote do
      Kernel.defp unquote(name)(unquote_splicing(params), { __MODULE__, { Process.Managed, _, _ } } = self) do
        import Kernel, except: [@: 1, send: 2]
        import Process.Managed, only: [send: 2]
        import OOP, only: [@: 1]
        unquote transform block
      end
    end
  end

  Kernel.defp defmethodp!(name, block) do
    quote do
      Kernel.defp unquote(name)({ __MODULE__, { Process.Managed, _, _ } } = self) do
        import Kernel, except: [@: 1, send: 2]
        import Process.Managed, only: [send: 2]
        import OOP, only: [@: 1]
        unquote transform block
      end
    end
  end

  Kernel.defp defreader!(name) do
    defmethod!(name, Code.string_to_quoted!("@" <> to_string(name)))
  end

  Kernel.defp defwriter!(name) do
    defmethod!(name, [{:value,[],nil}], Code.string_to_quoted!("@" <> to_string(name) <> "(value)"))
  end

  Kernel.defp defaccessor!(name) do
    quote do
      unquote defreader!(name)
      unquote defwriter!(name)
    end
  end

  Kernel.def new_server(dict) do
    receive do
      { pid, { attr, val } } ->
        send pid, { Kernel.self, val }
        new_server HashDict.put dict, attr, val
      { pid, attr } ->
        send pid, { Kernel.self, HashDict.get(dict, attr) }
        new_server(dict)
    end
  end

  Kernel.def new_server do
    Process.Managed.spawn(OOP, :new_server, [HashDict.new])
  end

  Kernel.defp transform({:=, _, [{ :@, line1, [{ var, line2, _ }]}, val] }) do
    { :@, line1, [{ var, line2, [transform(val)] }] }
  end

  Kernel.defp transform({ sym, line, r = [_|_] }) do
    { sym, line, Enum.map(r, transform(&(&1))) }
  end

  Kernel.defp transform(x), do: x
end
