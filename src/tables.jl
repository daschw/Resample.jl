function resample(table, index_col, new_inds, methods)
    @assert Tables.istable(table)
    ct = Tables.columntable(table)
    cols = Tables.columnnames(ct)
    index_col = get_index_col(cols, index_col)
    methods = get_table_methods(methods, cols, index_col)

    ct = Tables.columntable(sort(Tables.rowtable(ct), by=r->getproperty(r, index_col)))
    new_inds = get_new_indices(getproperty(ct, index_col), new_inds)

    if any(m -> isa(m, AbstractWeightedSampleMethod), values(methods))
        weighted_indices = resample_indices(getproperty(ct, index_col), new_inds, Mean())
        weights = Dict{AbstractWeightedSampleMethod, Vector{Vector{Float64}}}()
        for method in WEIGHTED_SAMPLE_METHODS
            if method in values(methods)
                weights[method] = resample_weights(
                    getproperty(ct, index_col),
                    new_inds,
                    weighted_indices,
                    method,
                )
            end
        end
    end

    single_indices = Dict{AbstractSingleSampleMethod, Vector{Int}}()
    for method in SINGLE_SAMPLE_METHODS
        if method in values(methods)
            single_indices[method] = resample_indices(getproperty(ct, index_col), new_inds, method)
        end
    end

    nt = (;
        (
            col => if col == index_col
                new_inds
            elseif methods[col] in WEIGHTED_SAMPLE_METHODS
                [dot(getproperty(ct, col)[weighted_indices[i]], weights[methods[col]][i]) for i in eachindex(new_inds)]
            else # if methods[col] in SINGLE_SAMPLE_METHODS
                [getproperty(ct, col)[single_indices[methods[col]][i]] for i in eachindex(new_inds)]
            end for col in cols
        )...
    )
end

resample(table, index_col, new_inds; methods...) = resample(table, index_col, new_inds, methods)


get_index_col(cols, index_col::Symbol) = index_col
get_index_col(cols, index_col::Int) = cols[index_col]

function get_table_methods(d, cols, index_col)
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

function get_table_methods(a::AbstractVector{<:AbstractSampleMethod}, cols, index_col)
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

function get_table_methods(m::AbstractSampleMethod, cols, index_col)
    return Dict(col => m for col in cols if col != index_col)
end
