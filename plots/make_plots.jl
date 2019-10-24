using Plots, Resample, Dates

times_long = DateTime(2019):Minute(5):DateTime(2019, 1, 1, 23, 55)
times_short = DateTime(2019):Hour(1):DateTime(2019, 1, 1, 23)

power_long = rand(length(times_long))
energy_long = power_long / 12

power_short = resample(power_long, times_long, times_short)
energy_short = resample(energy_long, times_long, times_short, Sum())

plot(times_long, power_long, label = "5 min", st = :step)
plot!(times_short, power_short, label = "1 h", st = :step)
png(joinpath(@__DIR__, "power"))

plot(times_long, cumsum(energy_long), label = "5 min", st = :step)
plot!(times_short, cumsum(energy_short), label = "1 h", st = :step)
png(joinpath(@__DIR__, "energy"))
