function resample(df::DataFrame, index_col, new_inds, methods = Mean())
    cols = names(df)
    index_col = get_index_col(cols, index_col)
    methods = get_dataframe_methods(methods, cols, index_col)
    df = sort(df, index_col)
    new_inds = get_new_indices(df[!, index_col], new_inds)

    if any(m -> isa(m, AbstractWeightedSampleMethod), values(methods))
        weighted_indices = resample_indices(df[!, index_col], new_inds, Mean())
        weights = Dict{AbstractWeightedSampleMethod, Vector{Vector{Float64}}}()
        for method in WEIGHTED_SAMPLE_METHODS
            if method in values(methods)
                weights[method] = resample_weights(df[!, index_col], new_inds, weighted_indices, method)
            end
        end
    end

    single_indices = Dict{AbstractSingleSampleMethod, Vector{Int}}()
    for method in SINGLE_SAMPLE_METHODS
        if method in values(methods)
            single_indices[method] = resample_indices(df[!, index_col], new_inds, method)
        end
    end

    new_df = DataFrame()
    for col in cols
        if col == index_col
            new_df[!, col] = new_inds
        elseif methods[col] in WEIGHTED_SAMPLE_METHODS
            new_df[!, col] = zeros(promote_type(eltype(df[!, col]), eltype(first(weights[methods[col]]))), size(new_inds))
            for i in eachindex(new_inds)
                new_df[i, col] = dot(df[weighted_indices[i], col], weights[methods[col]][i])
            end
        elseif methods[col] in SINGLE_SAMPLE_METHODS
            new_df[!, col] = similar(df[!, col], size(new_inds))
            for i in eachindex(new_inds)
                new_df[i, col] = df[single_indices[methods[col]][i], col]
            end
        end
    end
    return new_df
end


get_index_col(cols, index_col::Symbol) = index_col
get_index_col(cols, index_col::Int) = cols[index_col]

function get_dataframe_methods(d::Dict{Symbol, <:AbstractSampleMethod}, cols, index_col)
    col_methods = Dict{Symbol, AbstractSampleMethod}()

    for col in keys(d)
        if col in cols
            col_methods[col] = d[col]
        else
            @warn "The column name `:$col` could not be found and has been ignored."
        end
    end

    for col in cols
        if col != index_col && !haskey(col_methods, col)
            col_methods[col] = Mean()
        end
    end

    return col_methods
end

function get_dataframe_methods(a::AbstractVector{<:AbstractSampleMethod}, cols, index_col)
    n = length(cols) - 1

    if length(a) < n
        @warn "The provided methods vector is not long enough and will be repeated until the length $n is reached."
        a = a[mod1.(1:n), length(a)]
    elseif length(a) > n
        @warn "The provided methods vector is too long. Only the first $n elements will be used"
    end

    col_methods = Dict{Symbol, AbstractSampleMethod}()
    i = 1

    for col in cols
        if col != index_col
            col_methods[col] = a[i]
            i += 1
        end
    end

    return col_methods
end

function get_dataframe_methods(m::AbstractSampleMethod, cols, index_col)
    return Dict(col => m for col in cols if col != index_col)
end
