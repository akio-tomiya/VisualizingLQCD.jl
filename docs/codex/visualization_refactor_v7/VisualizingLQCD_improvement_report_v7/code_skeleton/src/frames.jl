function frame_map(nt::Integer; nloops::Integer=1)
    nt > 0 || error("nt must be positive")
    nloops > 0 || error("nloops must be positive")
    return [(frame=i, slice4=((i - 1) % nt) + 1) for i in 1:(nt * nloops)]
end
