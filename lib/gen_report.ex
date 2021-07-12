defmodule GenReport do
  alias GenReport.Parser

  def build(file_name) do
    file_name
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> sum_values(line, report) end)
  end

  def build() do
    {:error, "Insira o nome de um arquivo"}
  end

  def build_from_many(filename) when not is_list(filename) do
    {:error, "Please provide a list of strings"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)

    {:ok, result}
  end

  defp sum_values(
         [name, hours, _day, month, year],
         %{
           "all_hours" => all_hours,
           "hours_per_month" => hours_per_month,
           "hours_per_year" => hours_per_year
         }
       ) do
    all_hours = merge_maps(all_hours, %{name => hours})
    hours_per_month = merge_multi_maps(hours_per_month, %{name => %{month => hours}})
    hours_per_year = merge_multi_maps(hours_per_year, %{name => %{year => hours}})

    build_map(all_hours, hours_per_month, hours_per_year)
  end

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)
    hours_per_month = merge_multi_maps(hours_per_month1, hours_per_month2)
    hours_per_year = merge_multi_maps(hours_per_year1, hours_per_year2)

    build_map(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, v1, v2 -> v1 + v2 end)
  end

  defp merge_multi_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, v1, v2 ->
      merge_maps(v1, v2)
    end)
  end

  defp build_map(all_hours, hours_per_month, hours_per_year) do
    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end

  defp report_acc() do
    build_map(%{}, %{}, %{})
  end
end
