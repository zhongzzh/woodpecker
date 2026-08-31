function wcgain(usys::USS, Opt::WCOptions=wcOptions())
    return _wcgain(usys, nothing, Opt)
end

function wcgain(usys::USS, focus::Tuple{<:Real,<:Real}, Opt::WCOptions=wcOptions())
    return _wcgain(usys, focus, Opt)
end

function wcgain(usys::USS, frequency::AbstractVector{<:Real}, Opt::WCOptions=wcOptions())
    return _wcgain(usys, frequency, Opt)
end

function _wcgain(usys::USS, frequency_specification, Opt::WCOptions)
    @ccall_check_func_lic :TyRobustControl
    Opt.ULevel > 0 || error(@tr("ULevel must be positive."))
    mussv_options = if Opt.Display
        replace(Opt.MussvOptions, "s" => "")
    elseif occursin('s', Opt.MussvOptions)
        Opt.MussvOptions
    else
        string(Opt.MussvOptions, 's')
    end

    M, B, _, muB = ulftdata(usys.Data)
    if !muB["ismuStandard"]
        error(
            @tr(
                "Uncertainty structures with repeated, non-scalar blocks are not supported."
            )
        )
    end
    M = M.IC
    nblk = length(muB["BlkInfo"])
    StableFlag = isstable(M)
    ULevel = Opt.ULevel
    Ts = isdiscrete(M) ? M.Ts : 0
    frequency_mode, frequency_focus = _wcgain_frequency_input(frequency_specification, Ts)
    W = if frequency_mode == :points
        frequency_focus
    else
        _PickGrid(getDynamicRange(eigvals(M.A)), frequency_focus)
    end

    if !StableFlag
        error(@tr("Unstable systems are not supported temporarily."))
    elseif nblk == 0
        GPeak, WPeak = norm(M, Inf; tol=1e-6)
        if frequency_mode != :points &&
            first(frequency_focus) <= WPeak <= last(frequency_focus)
            W = sort(unique([WPeak; W]))
        end
        H = freqresp(M, W)
        g = zeros(length(W))
        for ct in eachindex(W)
            g[ct] = opnorm(H[:, :, ct])
        end
        peak_index = argmax(g)
        GPeak = g[peak_index]
        WPeak = W[peak_index]
        WCG = Dict(
            "UpperBound" => GPeak, "LowerBound" => GPeak, "CriticalFrequency" => WPeak
        )
        WCU = Dict()
        report_indices = if Opt.VaryFrequency || frequency_mode == :points
            collect(eachindex(W))
        else
            [peak_index]
        end
        Info = Dict(
            "Model" => 1,
            "Frequency" => W[report_indices],
            "Bounds" => hcat(g[report_indices], g[report_indices]),
            "WorstPerturbation" => Dict(),
            "Sensitivity" => Dict(),
        )
    else
        ny, nu = iosize(B)
        ne, nd = iosize(usys.Data)
        a, b, c, d = ssdata(M)
        if ne == 0 || nd == 0
            nx = size(a, 1)
            b = [b[:, 1:ny] zeros(nx, 1)]
            c = [c[1:nu, :]; zeros(1, nx)]
            d = blkdiag(d[1:nu, 1:ny], 0)
            ne = nd = 1
        end
        b[:, 1:ny] .*= sqrt(ULevel)
        c[1:nu, :] .*= sqrt(ULevel)
        d[:, 1:ny] .*= sqrt(ULevel)
        d[1:nu, :] .*= sqrt(ULevel)
        M = ss(a, b, c, d, M.timeevol)

        wcgainBlk = [muB["muBlkNby2"]; nd ne]
        fixedBlkIdx = collect(1:nblk)
        BlockName = vcat([blkinfo["BlockName"] for blkinfo in muB["BlkInfo"]]...)
        Frequency = W
        base_frequency = copy(Frequency)
        Mdata = freqresp(M, Frequency)
        bnds, tinfo = mussv(Mdata, wcgainBlk, mussv_options, fixedBlkIdx)

        if frequency_mode != :points && length(Frequency) > 1
            Frequency, Mdata, bnds, tinfo = _wcgain_refine_peak(
                M, Frequency, Mdata, bnds, tinfo, wcgainBlk, mussv_options, fixedBlkIdx
            )
        end

        lower_curve = vec(bnds[1, 2, :])
        upper_curve = vec(bnds[1, 1, :])
        gap_scale = max.(abs.(lower_curve), one(eltype(lower_curve)))
        if maximum((upper_curve .- lower_curve) ./ gap_scale) > 0.01
            forward_upper = _wcgain_continuation_upper(
                Mdata, bnds, tinfo, wcgainBlk, fixedBlkIdx
            )
            backward_upper = _wcgain_continuation_upper(
                Mdata, bnds, tinfo, wcgainBlk, fixedBlkIdx; reverse_order=true
            )
            upper_curve = max.(min.(forward_upper, backward_upper), lower_curve)
            if maximum((upper_curve .- lower_curve) ./ gap_scale) > 0.05
                anchor_upper = _wcgain_anchor_upper(
                    Mdata, bnds, tinfo, wcgainBlk, fixedBlkIdx
                )
                upper_curve = max.(min.(upper_curve, anchor_upper), lower_curve)
            end
            bnds[1, 1, :] .= upper_curve
        end

        pkl, WCIndex = findmax(bnds[1, 2, :])
        pku, upper_index = findmax(bnds[1, 1, :])
        LowerBound = max(pkl, zero(pkl))
        UpperBound = max(pku, zero(pku))
        WCG = Dict(
            "UpperBound" => UpperBound,
            "LowerBound" => LowerBound,
            "CriticalFrequency" => Frequency[WCIndex],
        )
        PertM = _mussvunwrap(tinfo.pvec, tinfo.blk; nargout=1)
        WCU = getWorstCasePerturbation(B, muB, PertM[:, :, WCIndex], Frequency[WCIndex])
        length(WCU) == 1 && (WCU = WCU[1])
        if Opt.Sensitivity
            Gamma = Opt.SensitivityPercent / 100
            Gamma > 0 || error("SensitivityPercent must be positive when Sensitivity=true.")
            npts = length(Frequency)
            idx = findall(vec(bnds[1, 1, :]) .>= pku * 0.85)
            if length(idx) == 1 && npts > 1
                if idx[1] == 1
                    idx = [idx[1], idx[1] + 1]
                else
                    idx = [idx[1] - 1, idx[1]]
                end
            end
            szB = iosize(B)
            M11 = Mdata[1:szB[2], 1:szB[1], :]
            matg = M11[:, :, idx]
            sfactor = zeros(nblk)
            SensMuOpt =
                occursin('s', mussv_options) ? mussv_options : string(mussv_options, 's')
            if contains(SensMuOpt, 'm')
                SensMuOpt = replace(SensMuOpt, "m" => "m0")
            end
            for k in 1:nblk
                tmpmat = copy(matg)
                szD = muB["BlkInfo"][k]["BlockSize"]
                affectedRows = (
                    muB["BlkInfo"][k]["ColStart"]:(muB["BlkInfo"][k]["ColStart"] + szD[2] - 1)
                )
                tmpmat[affectedRows, :, :] .*= 1 + Gamma
                name = muB["BlkInfo"][k]["BlockName"]
                if !strncmpi("rcastreserved", name, 13)
                    sbnds, _ = mussv(tmpmat, muB["muBlkNby2"], SensMuOpt)
                    pkus = vec(sbnds[1, 1, :])
                    oldpeak = vec(bnds[1, 1, idx])
                    if any(oldpeak .== 0 .&& pkus .> 0)
                        sfactor[k] = Inf
                    elseif all(oldpeak .== 0 .&& pkus .== 0)
                        sfactor[k] = 1
                    else
                        keepgz = findall(oldpeak .> 0)
                        sfactor[k] = maximum(
                            abs.(
                                (pkus[keepgz] - oldpeak[keepgz]) ./
                                (Gamma * oldpeak[keepgz]),
                            ),
                        )
                    end
                end
            end
            SensValues = [
                isfinite(value) ? round(Int, 100 * value) : value for value in sfactor
            ]
            Sensitivity = Dict(zip(BlockName, SensValues))
        else
            Sensitivity = Dict(zip(BlockName, NaN * ones(nblk)))
        end
        report_indices = if frequency_mode == :points
            collect(eachindex(Frequency))
        elseif Opt.VaryFrequency
            reported_frequency = sort(
                unique(vcat(base_frequency, Frequency[[WCIndex, upper_index]]))
            )
            searchsortedfirst.(Ref(Frequency), reported_frequency)
        else
            sort(unique([WCIndex, upper_index]))
        end
        Bounds = hcat(vec(bnds[1, 2, report_indices]), vec(bnds[1, 1, report_indices]))
        Info = Dict(
            "Model" => 1,
            "Frequency" => Frequency[report_indices],
            "Bounds" => Bounds,
            "WorstPerturbation" => WCU,
            "Sensitivity" => Sensitivity,
        )
    end
    return WCG, WCU, Info
end

function _wcgain_frequency_input(::Nothing, Ts::Real)
    return :automatic, [0.0, Ts == 0 ? Inf : pi / Ts]
end

function _wcgain_frequency_input(focus::Tuple{<:Real,<:Real}, Ts::Real)
    wmin, wmax = promote(float(focus[1]), float(focus[2]))
    isfinite(wmin) && !isnan(wmax) && 0 <= wmin < wmax ||
        error(@tr("The frequency range must satisfy 0 <= wmin < wmax."))
    if Ts != 0
        wmax <= pi / Ts || error(@tr("The frequency range exceeds the Nyquist frequency."))
    end
    return :range, [wmin, wmax]
end

function _wcgain_frequency_input(frequency::AbstractVector{<:Real}, Ts::Real)
    isempty(frequency) && error(@tr("The frequency vector must not be empty."))
    W = sort(unique(float.(collect(frequency))))
    all(isfinite, W) && all(w -> w >= 0, W) ||
        error(@tr("Frequencies must be finite and nonnegative."))
    if Ts != 0
        all(w -> w <= pi / Ts, W) ||
            error(@tr("The frequency vector exceeds the Nyquist frequency."))
    end
    return :points, W
end

function _wcgain_refine_peak(
    M, Frequency, Mdata, bnds, tinfo, wcgainBlk, mussv_options, fixedBlkIdx
)
    minimum_iterations = 2
    maximum_iterations = 3
    gain_tolerance = 1e-4
    for iteration in 1:maximum_iterations
        old_peak = maximum(bnds[1, 2, :])
        peak_index = argmax(vec(bnds[1, 2, :]))
        left_index = max(1, peak_index - 1)
        right_index = min(length(Frequency), peak_index + 1)
        left_index < right_index || break
        left_frequency = Frequency[left_index]
        right_frequency = Frequency[right_index]
        candidate_frequency = if left_frequency > 0
            collect(exp.(range(log(left_frequency), log(right_frequency); length=9)))
        else
            collect(range(left_frequency, right_frequency; length=9))
        end
        new_frequency = filter(candidate_frequency) do candidate
            all(existing -> !isapprox(candidate, existing; rtol=8eps(), atol=0), Frequency)
        end
        isempty(new_frequency) && break

        new_Mdata = freqresp(M, new_frequency)
        new_bnds, new_tinfo = mussv(new_Mdata, wcgainBlk, mussv_options, fixedBlkIdx)
        Frequency, Mdata, bnds, tinfo = _wcgain_merge_samples(
            Frequency, Mdata, bnds, tinfo, new_frequency, new_Mdata, new_bnds, new_tinfo
        )
        relative_improvement =
            (maximum(bnds[1, 2, :]) - old_peak) / max(abs(old_peak), eps(float(old_peak)))
        if iteration >= minimum_iterations && relative_improvement < gain_tolerance
            break
        end
    end
    return Frequency, Mdata, bnds, tinfo
end

function _wcgain_merge_samples(
    Frequency, Mdata, bnds, tinfo, new_frequency, new_Mdata, new_bnds, new_tinfo
)
    merged_frequency = vcat(Frequency, new_frequency)
    order = sortperm(merged_frequency)
    merged_frequency = merged_frequency[order]
    merged_Mdata = cat(Mdata, new_Mdata; dims=3)[:, :, order]
    merged_bnds = cat(bnds, new_bnds; dims=3)[:, :, order]
    merged_tinfo = MussvInfo(
        merged_bnds,
        cat(tinfo.dvec, new_tinfo.dvec; dims=3)[:, :, order],
        cat(tinfo.pvec, new_tinfo.pvec; dims=3)[:, :, order],
        cat(tinfo.gvec, new_tinfo.gvec; dims=3)[:, :, order],
        cat(tinfo.sens, new_tinfo.sens; dims=3)[:, :, order],
        tinfo.blk,
    )
    return merged_frequency, merged_Mdata, merged_bnds, merged_tinfo
end

function _wcgain_continuation_upper(
    Mdata::AbstractArray,
    bnds::AbstractArray,
    info,
    blk::AbstractMatrix{<:Integer},
    fixedBlkIdx::AbstractVecOrMat{<:Integer};
    reverse_order::Bool=false,
)
    npts = size(Mdata, 3)
    upper = vec(copy(bnds[1, 1, :]))
    npts <= 1 && return max.(upper, vec(bnds[1, 2, :]))

    index, _ = _mkBlkData(copy(blk), fixedBlkIdx)
    initial_index = reverse_order ? npts : 1
    order = reverse_order ? ((npts - 1):-1:1) : (2:npts)
    previous_Dr, previous_Dc, _, previous_Gcr = _LMIunwrapdg(
        info.dvec[:, :, initial_index],
        info.gvec[:, :, initial_index],
        blk,
        bnds[:, :, initial_index],
    )

    for point_index in order
        previous_index = reverse_order ? point_index + 1 : point_index - 1
        lower = bnds[1, 2, point_index]
        accepted = false
        try
            candidate_ub, candidate_Dr, DcF, DcV, candidate_Gcr = _mudescentub(
                Mdata[:, :, point_index],
                index,
                upper[previous_index],
                previous_Dr,
                previous_Dc,
                previous_Gcr,
            )
            bound_tolerance = sqrt(eps(float(one(lower)))) * max(lower, one(lower))
            if isfinite(candidate_ub) && candidate_ub + bound_tolerance >= lower
                upper[point_index] = min(upper[point_index], max(candidate_ub, lower))
                previous_Dr = candidate_Dr
                previous_Dc = DcF + DcV
                previous_Gcr = candidate_Gcr
                accepted = true
            end
        catch
            accepted = false
        end

        if !accepted
            previous_Dr, previous_Dc, _, previous_Gcr = _LMIunwrapdg(
                info.dvec[:, :, point_index],
                info.gvec[:, :, point_index],
                blk,
                bnds[:, :, point_index],
            )
        end
    end
    return max.(upper, vec(bnds[1, 2, :]))
end

function _wcgain_anchor_upper(
    Mdata::AbstractArray,
    bnds::AbstractArray,
    info,
    blk::AbstractMatrix{<:Integer},
    fixedBlkIdx::AbstractVecOrMat{<:Integer},
)
    npts = size(Mdata, 3)
    upper = vec(copy(bnds[1, 1, :]))
    lower = vec(bnds[1, 2, :])
    npts <= 1 && return max.(upper, lower)

    gap_tolerance = 0.05 .* max.(lower, one(eltype(lower)))
    anchors = findall((upper .>= lower) .&& ((upper .- lower) .<= gap_tolerance))
    isempty(anchors) && return max.(upper, lower)
    index, _ = _mkBlkData(copy(blk), fixedBlkIdx)

    for point_index in 1:npts
        anchor_candidates = Int[]
        left = searchsortedlast(anchors, point_index - 1)
        right = searchsortedfirst(anchors, point_index + 1)
        left > 0 && push!(anchor_candidates, anchors[left])
        right <= length(anchors) && push!(anchor_candidates, anchors[right])

        for anchor_index in anchor_candidates
            try
                anchor_Dr, anchor_Dc, _, anchor_Gcr = _LMIunwrapdg(
                    info.dvec[:, :, anchor_index],
                    info.gvec[:, :, anchor_index],
                    blk,
                    bnds[:, :, anchor_index],
                )
                candidate_ub, _, _, _, _ = _mudescentub(
                    Mdata[:, :, point_index],
                    index,
                    upper[anchor_index],
                    anchor_Dr,
                    anchor_Dc,
                    anchor_Gcr,
                )
                bound_tolerance =
                    sqrt(eps(float(one(lower[point_index])))) *
                    max(lower[point_index], one(lower[point_index]))
                if isfinite(candidate_ub) &&
                    candidate_ub + bound_tolerance >= lower[point_index]
                    upper[point_index] = min(
                        upper[point_index], max(candidate_ub, lower[point_index])
                    )
                end
            catch
            end
        end
    end
    return max.(upper, lower)
end
