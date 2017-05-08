defmodule OptimizePrecomputed do
  defmacro optimize_for(inputs, do: def_function_code) do
    #IO.inspect def_function_code
    info = extract_function_info def_function_code
    anon_fun_code = quote do
      compile_time_fn =
        fn (unquote_splicing(info.args)) ->
          unquote(info.do_block)
        end
    end

    result_optimized = quote bind_quoted: [inputs: inputs, name: info.name] do
      for args <- inputs do
        @optimized_result apply(compile_time_fn, args)
        def unquote(name)(unquote_splicing(args)), do: @optimized_result
      end
    end

    result =
        quote do
          unquote(anon_fun_code)
          unquote(result_optimized)
          unquote(info.code)
        end
        #IO.puts result |> Macro.to_string
    result
  end

  defp extract_function_info(code) do
    case code do
      {:def, _, [{fun_name, _, args}, [do: do_block]]} ->
        %{code: code, name: fun_name, do_block: do_block, args: args}
      _ ->
        raise "The optimize_for macro should receive a single function definition"
    end
  end
end
