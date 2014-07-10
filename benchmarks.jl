# bring in definitions
require("activ.jl")
require("mlp.jl")
require("backprop.jl")
require("train.jl")

using DataFrames 
using MLBase

bicycle = readtable("./datasets/bicycle_demand.csv") # load test data

function dataprep(data)
    year    = int(map(x->x[1:4],data[:datetime]))
    month   = int(map(x->x[6:7],data[:datetime]))
    day     = int(map(x->x[9:10],data[:datetime]))
    hour    = int(map(x->x[12:13],data[:datetime]))
    X = hcat(year,month,hour,array(data[[:season,:temp,:holiday,:workingday,:weather,:atemp,:humidity,:windspeed]]))'
    T = array(data[[:count]])'

    X = convert(Array{Float64,2},X)
    T = convert(Array{Float64,2},T)
    return X,T
end

function untransform(t::Standardize, x::Array)
    (x .+ t.mean .* t.scale) ./ t.scale
end

X,T = dataprep(bicycle)

X = X[:,1:100:end] # reduce the size of the data set by a factor of 100
T = T[:,1:100:end]

trans_x = estimate(Standardize, X; center=true, scale=true)
trans_t = estimate(Standardize, T; center=true, scale=true)

transform!(trans_x,X)
transform!(trans_t,T)

ind = size(X,1)
outd = size(T,1)

layer_sizes = [ind, 6, outd]
act   = [logis,  ident]
actd  = [logisd, identd]

# not working 100%, it's a difficult set to get to converge in a sensible time period

println("Training...")

mlp = MLP(rand, layer_sizes, act, actd)
params = TrainingParams(1_000, 1e-5, 2e-6, .7, :levenberg_marquardt)
mlp = train(mlp, params, X, T, verbose=false)

@show untransform(trans_t,T)
@show untransform(trans_t,prop(mlp,X))