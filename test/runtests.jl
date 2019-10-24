using Resample
using Test
using Dates
using DataFrames
using Statistics


times_long = DateTime(2019):Minute(5):DateTime(2019, 1, 31, 23, 55)
times_short = DateTime(2019):Hour(1):DateTime(2019, 1, 31, 23)

inds_long = eachindex(times_long)
inds_short = 1:12:length(times_long)

power_long = rand(length(times_long))
energy_long = power_long / 12

df = DataFrame(
    Index = inds_long,
    Time = times_long,
    Power = power_long,
    Energy = energy_long,
)

power_short_times = resample(power_long, times_long, times_short)
power_short_inds = resample(power_long, inds_long, inds_short)
power_short_step = resample(power_long, times_long, Hour(1))

energy_short_times = resample(energy_long, times_long, times_short, Sum())
energy_short_inds = resample(energy_long, inds_long, inds_short, Sum())
energy_short_step = resample(energy_long, times_long, Hour(1), Sum())

df_short_times = resample(df, :Time, times_short, [First(), Mean(), Sum()])
df_short_inds = resample(df, :Index, inds_short, [First(), Mean(), Sum()])
df_short_step = resample(df, :Time, Hour(1), [First(), Mean(), Sum()])

@testset "Resample" begin
    @test power_short_times == power_short_inds == power_short_step
    @test energy_short_times == energy_short_inds == energy_short_step
    @test df_short_times == df_short_inds == df_short_step

    @test mean(power_long) ≈ mean(power_short_times)
    @test sum(energy_long) ≈ sum(energy_short_times)
end
