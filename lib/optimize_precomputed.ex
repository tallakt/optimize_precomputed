defmodule OptimizePrecomputed do
  @error_message "The optimize_for macro should receive a single function definition"

  #clause1 = quote do: ([1, 2])
  #clause2 = quote do: :test
  #clause3 = quote do: (
  #unquote_splicing(clause1) -> (unquote(clause2))
  #)
  #funny = quote do: (fn
    #unquote_splicing(clause1) -> (unquote(clause2))
    #_ -> :nope
    #end)
    ##funny2 = quote do: (fn
      ##unquote_splicing(clause)
      ##end)
      #IO.puts "CLAUSE"
      #IO.inspect((clause1))
      #IO.inspect((clause2))
      #IO.inspect((clause3))
      #IO.inspect((funny))
      #IO.puts(Macro.to_string(clause1))
      #IO.puts(Macro.to_string(clause2))
      #IO.puts(Macro.to_string(funny))

  defmacro optimize_for(inputs, do: def_function_code) do
    IO.inspect def_function_code
    {defs_nobody, defs_body} =
      def_function_code
      |> extract_function_info
      |> split_empty_and_body_declarations


    anon_function_clauses =
      defs_body
      |> Enum.map(fn %{args: a, do_block: d} ->
          quote do
            (unquote_splicing(a)) ->
              unquote(d)
          end
        end)
      |> join_code

    IO.puts "DEFS BODY"
    IO.inspect defs_body
    IO.puts "DEFS ANON CLAUSES"
    IO.inspect anon_function_clauses
    IO.puts anon_function_clauses |> Macro.to_string

    first_function_def = Enum.at(defs_body, 0)

    anon_fun_code_bare = {:fn, [], anon_function_clauses}
    anon_fun_code = quote do
      compile_time_fn = unquote(anon_fun_code_bare)
    end
    IO.puts "ANON"
    IO.inspect anon_fun_code
    IO.puts anon_fun_code |> Macro.to_string

    result_optimized = quote bind_quoted: [inputs: inputs, name: first_function_def.name] do
      for args <- inputs do
        @optimized_result apply(compile_time_fn, args)
        def unquote(name)(unquote_splicing(args)), do: @optimized_result
      end
    end

    result = join_code(
      Enum.map(defs_nobody, fn %{code: c} -> c end) ++
      [anon_fun_code, result_optimized] ++
      Enum.map(defs_body, fn %{code: c} -> c end)
      )
    #IO.puts result |> Macro.to_string
    result
  end


  defp join_code(snippets) do
    Enum.reduce(snippets, nil, fn
    c, nil ->
      quote do
        unquote(c)
      end
    c, acc ->
      quote do
        unquote(acc)
        unquote(c)
      end
    end)
  end


  defp split_empty_and_body_declarations(function_info) do
    function_info
    |> Enum.split_while(fn %{do_block: d} -> !d end)
  end

  defp extract_function_info(code) do
    result =
      code
      |> do_extract_function_info
      |> IO.inspect

    if !has_a_single_function_declaration?(result) do
      raise @error_message
    end
    if !has_equal_parameter_counts?(result) do
      raise @error_message
    end
    result
  end

  defp do_extract_function_info(code = {:def, _, [{fun_name, _, args}]}) do
    # empty declaration
    [%{code: code, name: fun_name, do_block: nil, args: args}]
  end

  defp do_extract_function_info(code = {:def, _, [{fun_name, _, args}, [do: do_block]]}) do
    [%{code: code, name: fun_name, do_block: do_block, args: args}]
  end

  defp do_extract_function_info(code = {:__block__, [], defs}) do
    Enum.flat_map(defs, fn def_code -> do_extract_function_info(def_code) end)
  end

  defp do_extract_function_info(code) do
    raise @error_message
  end

  defp has_a_single_function_declaration?(definitions) do
    unique_names = 
      definitions
      |> Enum.map(fn %{name: n} -> n end)
      |> Enum.uniq
    Enum.count(unique_names) == 1
  end

  defp has_equal_parameter_counts?(definitions) do
    unique_param_counts = 
      definitions
      |> Enum.map(fn %{args: a} -> Enum.count(a) end)
      |> Enum.uniq
    Enum.count(unique_param_counts) == 1
  end
end
