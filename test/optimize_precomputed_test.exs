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

  @to_optimize_args (for i <- 1..20, do: [i])
  OptimizePrecomputed.optimize_for(@to_optimize_args) do
    def fib_optimized(n) do
      Helper.fib(n)
    end
  end
  
  send self(), :compilation_phase
  OptimizePrecomputed.optimize_for([[0]]) do
    def impure_function(_) do
      receive do
        x ->
          x
      after
        0 ->
         nil
      end
    end
  end

  defp fib(n), do: Helper.fib(n)

  test "the optimized fib function returns correct values" do
    assert fib_optimized(0) == fib(0)
    assert fib_optimized(1) == fib(1)
    assert fib_optimized(2) == fib(2)
    assert fib_optimized(5) == fib(5)
  end

  test "make sure that functions are optimized" do
    assert impure_function(1) == nil
    assert impure_function(0) == :compilation_phase
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
end
