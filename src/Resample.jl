module Resample

import LinearAlgebra: dot
import Statistics: mean

using DataFrames
using Dates

export resample
export Mean, Sum, First, Last, Min, Max, None


abstract type AbstractSampleMethod end

abstract type AbstractWeightedSampleMethod <: AbstractSampleMethod end
abstract type AbstractSingleSampleMethod <: AbstractSampleMethod end

struct Mean <: AbstractWeightedSampleMethod end
struct Sum <: AbstractWeightedSampleMethod end

struct First <: AbstractSingleSampleMethod end
struct Last <: AbstractSingleSampleMethod end
struct Min <: AbstractSingleSampleMethod end
struct Max <: AbstractSingleSampleMethod end

struct None <: AbstractSampleMethod end


const WEIGHTED_SAMPLE_METHODS = (Mean(), Sum())
const SINGLE_SAMPLE_METHODS = (First(),)


include("dataframes.jl")


function resample(data::AbstractVector, org_inds, new_inds, method::AbstractWeightedSampleMethod = Mean())
    data, org_inds = sort_input(data, org_inds)
    new_inds = get_new_indices(org_inds, new_inds)
    inds, weights = resample_indices_and_weights(org_inds, new_inds, method)
    new_data = zeros(size(new_inds))
    for i in eachindex(new_data)
        new_data[i] = dot(data[inds[i]], weights[i])
    end

    return new_data
end


function resample(data::AbstractVector, org_inds, new_inds, method::AbstractSingleSampleMethod)
    data, org_inds = sort_input(data, org_inds)
    new_inds = get_new_indices(org_inds, new_inds)
    inds = resample_indices(org_inds, new_inds, method)
    new_data = similar(data, size(new_inds))
    for i in eachindex(new_data)
        new_data[i] = data[inds[i]]
    end

    return new_data
end


function resample(data::AbstractVector, org_inds, new_inds, ::None)
    @warn "The resample method `None()` is a placeholder to ignore DataFrame columns in resampling."
end


function sort_input(data, org_inds)
    sort_inds = issorted(org_inds) ? eachindex(org_inds) : sortperm(org_inds)
    return data[sort_inds], org_inds[sort_inds]
end


function resample_indices_and_weights(org_inds, new_inds, method)
    Δ = mean(diff(new_inds))

    inds = [1:0 for i in eachindex(new_inds)]
    weights = [Float64[] for i in eachindex(new_inds)]

    for i in eachindex(new_inds)
        start = new_inds[i]
        stop = i == length(new_inds) ? new_inds[i] + Δ : new_inds[i + 1]
        inds[i], weights[i] = get_sample(org_inds, start, stop, method)
    end

    return inds, weights
end


function resample_indices(org_inds, new_inds, method)
    Δ = mean(diff(new_inds))
    inds = initialize_indices(length(new_inds), method)

    for i in eachindex(inds)
        start, stop = get_limits(new_inds, i, Δ)
        inds[i] = sample_indices(org_inds, start, stop, method)
    end

    return inds
end


function resample_indices(org_inds, new_inds, method::First)
    inds = initialize_indices(length(new_inds), method)

    for i in eachindex(inds)
        ind = findlast(j -> j <= new_inds[i], org_inds)
        if ind === nothing
            ind = 1
        end
        inds[i] = ind
    end

    return inds
end


function resample_weights(org_inds, new_inds, inds, method)
    Δ = mean(diff(new_inds))
    weights = [Float64[] for i in eachindex(new_inds)]

    for i in eachindex(new_inds)
        start, stop = get_limits(new_inds, i, Δ)
        weights[i] = sample_weights(org_inds, extrema(inds[i])..., start, stop, method)
    end

    return weights
end


initialize_indices(n, ::AbstractWeightedSampleMethod) = [1:0 for i in 1:n]
initialize_indices(n, ::AbstractSingleSampleMethod) = zeros(Int, n)


function get_limits(indices, i, Δ)
    start = indices[i]
    stop = i == length(indices) ? indices[i] + Δ : indices[i + 1]
    return start, stop
end


function sample_indices(org_inds, start, stop, ::AbstractWeightedSampleMethod)
    istart = findlast(i -> i <= start, org_inds)
    if istart === nothing
        istart = 1
    end
    istop = findlast(i -> i < stop, org_inds)
    if istop === nothing
        istop = 1
    end
    return istart:istop
end


function sample_weights(org_inds, istart, istop, start, stop, ::Mean)
    weights = diff([start; org_inds[istart + 1:istop]; stop]) ./ (stop - start)
    return weights
end


function sample_weights(org_inds, istart, istop, start, stop, ::Sum)
    start_prev = org_inds[istart]
    stop_next = istop == length(org_inds) ? stop : org_inds[istop + 1]

    weights = if istart == istop
        [(stop_next - start_prev) / (stop - start)]
    else
        start_next = org_inds[istart + 1]
        wstart = (start_next - start) / (start_next - start_prev)

        stop_prev = org_inds[istop]
        wstop = (stop - stop_prev) / (stop_next - stop_prev)

        [wstart; ones(istop - istart - 1); wstop]
    end
    return weights
end


function get_sample(org_inds, start, stop, method::Mean)
    istart, istop = extrema(sample_indices(org_inds, start, stop, method))
    weights = diff([start; org_inds[istart + 1:istop]; stop]) ./ (stop - start)
    return istart:istop, weights
end


function get_sample(org_inds, start, stop, method::Sum)
    istart, istop = extrema(sample_indices(org_inds, start, stop, method))

    start_prev = org_inds[istart]
    stop_next = istop == length(org_inds) ? stop : org_inds[istop + 1]

    weights = if istart == istop
        [(stop_next - start_prev) / (stop - start)]
    else
        start_next = org_inds[istart + 1]
        wstart = (start_next - start) / (start_next - start_prev)

        stop_prev = org_inds[istop]
        wstop = (stop - stop_prev) / (stop_next - stop_prev)

        [wstart; ones(istop - istart - 1); wstop]
    end
    return istart:istop, weights
end

get_new_indices(org_inds, new_inds::AbstractVector) = new_inds
get_new_indices(org_inds, step) = first(org_inds):step:last(org_inds)


end # module
