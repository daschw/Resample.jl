using Resample
using Test
using CSV
using Dates

data = CSV.read(joinpath(homedir(), "Cloud", "TU Wien", "Shared", "2018_Flex+", "WP3_Einsatzoptimierung", "Modelling", "Data-IDM", "heatpump_data.csv"))

day_inds = findall(t -> DateTime(2019, 5, 12) <= t < DateTime(2019, 5, 13), data.DateTime)

using DataFrames, BenchmarkTools
outdoor_temperature = DataFrame(DateTime = data.DateTime[day_inds], Temperature = data.OutdoorTemperature[day_inds])

new_inds = DateTime(2019, 4, 30):Minute(15):DateTime(2019, 5, 30, 23, 45)
# org_inds = data.DateTime
# vals = data.OutdoorTemperature

x = @btime resample(outdoor_temperature, :DateTime, new_inds)
y = @btime resample_new(outdoor_temperature, :DateTime, new_inds)

x == y

resample(new_inds, org_inds, vals)

using BenchmarkTools

may_inds = findall(dt -> DateTime(2019, 4, 30) <= dt < DateTime(2019, 5, 30), org_inds)

@btime resample(new_inds, org_inds, vals)
@btime x = resample(new_inds, org_inds, vals)
@btime y = resample(new_inds, org_inds, vals, Sum())

plot(org_inds, vals, st = :step, xlims = (Dates.value(DateTime(2019, 4, 30)), Inf))
plot!(new_inds, resample(new_inds, org_inds, vals), st = :step, xlims = (Dates.value(DateTime(2019, 5)), Inf))
xlims!((Dates.value(DateTime(2019, 5, 12)), Dates.value(DateTime(2019, 5, 13))))

@testset "Resample.jl" begin
    # Write your own tests here.
end

using DataFrames
df = DataFrame(A = rand(10), b = 1:10)

sort(df, :A)

df[:C] = rand(Bool, 10)

df[!, :D] = randn(10)

df

df = DataFrame()

df[!, :A] = rand(10)

df

a = rand(10)
b = 1:10

promote_type(typeof(a), typeof(b))

Vector{promote_type(eltype(a), eltype(b))}(undef, 5)
