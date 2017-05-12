defmodule Helper do
  def fib(0), do: 0
  def fib(1), do: 1
  def fib(n) when n > 0, do: fib(n - 1) + fib(n - 2)
end

defmodule OptimizePrecomputedTest do
  use ExUnit.Case
  require OptimizePrecomputed
  require Helper
  doctest OptimizePrecomputed


  #@OptimizePrecomputed.optimize_for(@to_optimize_args) do
    #@def fib_optimized1(n)
    #@def fib_optimized1(n), do: Helper.fib(n)
    #@end
    #@
    #@OptimizePrecomputed.optimize_for(@to_optimize_args) do
      #@def fib_optimized2(n), do: Helper.fib(n)
      #@def fib_optimized2(n) when n > 3, do: Helper.fib(n)
      #@end
  
  defp fib(n), do: Helper.fib(n)

  @module_string (__MODULE__ |> to_string |> String.replace(~r/Elixir./, ""))

  @compilable1 """
    defmodule #{@module_string}.Compileable1 do
      require OptimizePrecomputed
      @to_optimize_args (for i <- 1..20, do: [i])
      OptimizePrecomputed.optimize_for(@to_optimize_args) do
        def fib(n), do: Helper.fib(n)
      end
    end
  """

  test "the simple optimized fib function" do
    Code.compile_string @compilable1
    alias __MODULE__.Compileable1, as: C
    assert C.fib(0) == fib(0)
    assert C.fib(1) == fib(1)
    assert C.fib(2) == fib(2)
    assert C.fib(5) == fib(5)
  end

  @compilable2 """
    defmodule #{@module_string}.Compileable2 do
      require OptimizePrecomputed
      @to_optimize_args (for i <- 1..20, do: [i])
      OptimizePrecomputed.optimize_for(@to_optimize_args) do
        def fib(n)
        def fib(n), do: Helper.fib(n)
      end
    end
  """
  
  test "the optimized fib with empty declarations works" do
    Code.compile_string @compilable2
    alias __MODULE__.Compileable2, as: C
    assert C.fib(0) == fib(0)
    assert C.fib(1) == fib(1)
    assert C.fib(2) == fib(2)
    assert C.fib(5) == fib(5)
  end

  @compilable3 """
    defmodule #{@module_string}.Compileable3 do
      require OptimizePrecomputed
      @to_optimize_args (for i <- 1..20, do: [i])
      OptimizePrecomputed.optimize_for(@to_optimize_args) do
        def fib(n), do: Helper.fib(n)
        def fib(n) when n == 5, do: 99
      end
    end
  """
  
  test "the optimized fib with multiple declarations works" do
    Code.compile_string @compilable3
    alias __MODULE__.Compileable3, as: C
    assert C.fib(0) == fib(0)
    assert C.fib(1) == fib(1)
    assert C.fib(2) == fib(2)
    assert C.fib(5) == 99
  end

  @compilable4 """
    send self(), :compilation_phase
    defmodule #{@module_string}.Compileable4 do
      require OptimizePrecomputed
      OptimizePrecomputed.optimize_for([[0]]) do
        def impure(_) do
          receive do
            x ->
              x
          after
            0 ->
             nil
          end
        end
      end
    end
  """

  test "make sure that functions are optimized" do
    Code.compile_string @compilable4
    alias __MODULE__.Compileable4, as: C
    assert C.impure(1) == nil
    assert C.impure(0) == :compilation_phase
  end

  @uncompilable1 """
    defmodule #{@module_string}.Uncompilable1 do
      require OptimizePrecomputed

      OptimizePrecomputed.optimize_for([[0]]) do
        def a(_), do: 1
        def a(_, _), do: 2
      end
    end
  """

  test "should not compile multiple function definitions" do
    assert_raise RuntimeError, fn ->
      Code.compile_string @uncompilable1
    end
  end


  # todo test recursion
  # todo test multiple definition clauses
  # todo test with "when" conditions
  # todo test if a function has a when cause that is optimized away
  # todo test code inside other than def statements
  # todo test if multiple def function names are supplied
  # a function definition without a body must come before other stuff
  # todo: check format of input arguments, list of lists
  # issue: can't use module functions as they are not available during compile time
  # check that docs are preserved
end
