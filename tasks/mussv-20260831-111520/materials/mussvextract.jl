struct MussvInfo{T<:Real,S<:Number}
    bnds::Union{Array{T},FRD{T}}
    dvec::Union{Array{S},FRD{S}}
    pvec::Union{Array{S},FRD{S}}
    gvec::Union{Array{S},FRD{S}}
    sens::Union{Array{T},FRD{T}}
    blk::Matrix{<:Integer}
end

function mussvextract(Info::MussvInfo;nargout::Int = 1)
    @ccall_check_func_lic :TyRobustControl
    if nargout >= 1
        VDelta = _mussvunwrap(Info;nargout=1)
        nargout == 1 && return VDelta
    end
    if nargout >= 2
        (DLeft,DRight),(GLeft,GMiddle,GRight) = _mussvunwrap(Info;nargout=5)
        VSigma = Dict("DLeft" => DLeft,"DRight" => DRight,"GLeft" => GLeft,"GMiddle" => GMiddle,"GRight" => GRight)
        nargout == 2 && return VDelta,VSigma
    end
    if nargout >= 3
        Dr,Dc,Grc,Gcr = _mussvunwrap(Info;nargout=4)
        VLmi = Dict("Dr" => Dr,"Dc" => Dc,"Grc" => Grc,"Gcr" => Gcr)
        return VDelta,VSigma,VLmi
    end
end

function _mussvunwrap(Info::MussvInfo;nargout::Int)
    if nargout == 1
        return _unwrapp(Info.pvec,Info.blk)
    elseif nargout == 2
        return _unwrapd(Info.dvec,Info.blk)
    elseif nargout == 3
        return _unwrapg(Info.gvec,Info.blk)
    elseif nargout == 4
        return _LMIunwrapdg(Info.dvec,Info.gvec,Info.blk,Info.bnds)
    elseif nargout == 5
        # return (_unwrapd(Info.dvec,Info.blk)...,_unwrapg(Info.gvec,Info.blk)...)
        return _unwrapd(Info.dvec,Info.blk),_unwrapg(Info.gvec,Info.blk)
    elseif nargout == 6
        return _unwrapd(Info.dvec,Info.blk),_unwrapg(Info.gvec,Info.blk),_unwrapp(Info.pvec,Info.blk)
    else
        error(@tr("Invalid Input Arguments"))
    end
end

function _mussvunwrap(trow,blk;nargout::Int)
    if nargout == 1
        return _unwrapp(trow,blk)
    elseif nargout == 2
        return _unwrapd(trow,blk)
    elseif nargout == 3
        return _unwrapg(trow,blk)
    else
        error(@tr("Invalid Input Arguments"))
    end
end

function _mussvunwrap(rowd::AbstractArray,rowg::AbstractArray,blk::AbstractMatrix;nargout::Int)
    if nargout == 5
        return _unwrapd(rowd,blk),_unwrapg(rowg,blk)    
    end
end

function _mussvunwrap(rowd::AbstractArray,rowg::AbstractArray,blk::AbstractMatrix,bnds::AbstractArray;nargout::Int)
    if nargout == 4
        return _unwrapdg(rowd,rowg,blk,bnds)
    elseif nargout == 6
        return _unwrapd(rowd,bnds),_unwrapg(rowg,bnds),_unwrapp(blk,bnds)
    end
end

function _unwrapp(rowp::AbstractArray,blk::AbstractMatrix)
    szm = size(rowp)
    exd = length(szm) == 2 ? Int[] : szm[3:end]
    npts = round(Int,prod(exd))
    mat = reshape(rowp,szm[1],szm[2],npts)
    pcols = szm[2]
    szm[1] == 1 || error(@tr("Invalid ROWP, incorrect number of rows"))
    Or,Oc,Ur,Uc,Kc,Kr,Jc,Jr,Fc,Fr,csc,csr,nJ,nF,jcJ,jrJ,fcF,wd,wdf,wg,wp,wps,LKc,LKr,LFc,LFr,LJc,LJr,Ldmask,Lpmask = LOCALunwrap(blk)
    pcols == wp || error(@tr("ROWP is the wrong size"))
    T = eltype(mat)
    pert = zeros(T,csr[4],csc[4],exd...)
    tprt = zeros(T,csr[4],csc[4])
    # pert = isempty(exd) ? zeros(T,csr[4],csc[4]) : zeros(T,csr[4],csc[4],exd)
    # tprt = isempty(exd) ? zeros(T,csr[4],csc[4]) : zeros(T,csr[4],csc[4],exd)
    tpj = zeros(T,sum(Jr),sum(Jc))
    for i = 1:npts
        trowp = mat[:,:,i]
        if sum(Jc) != 0 
            tpj[find(Lpmask)] = trowp[wps+1:wp]
            tprt[find(LJr),find(LJc)] = tpj
        end
        if sum(Fc) != 0 
            tprt[find(LFr),find(LFc)] = diagm(diag(fcF'*diagm(trowp[1:wps])*fcF))
        end
        pert[:,:,i] = tprt[Ur,Uc]
    end
    return pert
end

function _unwrapp(rowp::FRD,blk::AbstractMatrix)
    pert = _unwrapp(rowp.ResponseData, blk)
    pert = frd(pert, rowp.Frequency, rowp.Ts; TimeUnit = rowp.TimeUnit)
    return pert
end

function _unwrapd(rowd::AbstractArray,blk::AbstractMatrix)
    szm = size(rowd)
    exd = length(szm) == 2 ? Int[] : szm[3:end]
    npts = round(Int,prod(exd))
    mat = reshape(rowd,szm[1],szm[2],npts)
    szm[1] == 1 || error(@tr("Invalid ROWP, incorrect number of rows"))
    Or,Oc,Ur,Uc,Kc,Kr,Jc,Jr,Fc,Fr,csc,csr,nJ,nF,jcJ,jrJ,fcF,wd,wdf,wg,wp,wps,LKc,LKr,LFc,LFr,LJc,LJr,Ldmask,Lpmask = LOCALunwrap(blk)
    szm[2] == wd || error(@tr("ROWD is the wrong size"))
    T = eltype(mat)
    dl = isempty(exd) ? zeros(T,csc[4],csc[4]) : zeros(T,csc[4],csc[4],exd)
    dr = isempty(exd) ? zeros(T,csr[4],csr[4]) : zeros(T,csr[4],csr[4],exd)
    tdl = zeros(T,csc[4],csc[4])
    tdr = zeros(T,csr[4],csr[4])
    tdf = zeros(T,csc[3],csc[3])
    for i=1:npts
        trowd = mat[:,:,i]
        if sum(Fc) != 0 
            tdf[find(Ldmask)] = trowd[1:wdf]
            tdl[find(LFc),find(LFc)] = tdf
            tdr[find(LFr),find(LFr)] = tdf
        end
        if sum(Jc) != 0 
           tdl[find(LJc),find(LJc)] = diagm(diag(jcJ'*diagm(trowd[wdf+1:wd])*jcJ))
           tdr[find(LJr),find(LJr)] = diagm(diag(jrJ'*diagm(trowd[wdf+1:wd])*jrJ))
        end
        dl[:,:,i] = tdl[Uc,Uc]
        dr[:,:,i] = tdr[Ur,Ur]
    end
    return dl,dr
end

function _unwrapd(rowd::FRD,blk::AbstractMatrix)
    dl,dr = _unwrapd(rowd.ResponseData,blk)
    dl = frd(dl,rowd.Frequency,rowd.Ts;TimeUnit = rowd.TimeUnit)
    dr = frd(dr,rowd.Frequency,rowd.Ts;TimeUnit = rowd.TimeUnit)
    return dl,dr
end

function _unwrapg(rowg::AbstractArray,blk::AbstractMatrix)
    szm = size(rowg)
    exd = length(szm) == 2 ? Int[] : szm[3:end]
    npts = round(Int,prod(exd))
    mat = reshape(rowg,szm[1],szm[2],npts)
    grows = szm[1]
    gcols = szm[2]
    if grows == 0
        idx = find(blk[:,2] .== 0)
        blk[idx,2] = blk[idx,1]
        nr = sum(blk[:,2])
        nc = sum(blk[:,1])
        return zeros(nr,nr),zeros(nr,nc),zeros(nc)
    elseif grows != 1
        error(@tr("Invalid ROWG, incorrect number of rows"))
    end
    Or,Oc,Ur,Uc,Kc,Kr,Jc,Jr,Fc,Fr,csc,csr,nJ,nF,jcJ,jrJ,fcF,wd,wdf,wg,wp,wps,LKc,LKr,LFc,LFr,LJc,LJr,Ldmask,Lpmask = LOCALunwrap(blk)
    gcols == wg || error(@tr("ROWG is the wrong size"))
    T = eltype(mat)
    gl = isempty(exd) ? zeros(T,csc[4],csc[4]) : zeros(T,csc[4],csc[4],exd)
    gm = isempty(exd) ? zeros(T,csc[4],csr[4]) : zeros(T,csc[4],csr[4],exd)
    gr = isempty(exd) ? zeros(T,csr[4],csr[4]) : zeros(T,csr[4],csr[4],exd)
    tgl = zeros(T,csc[4],csc[4])
    tgm = zeros(T,csc[4],csr[4])
    tgr = zeros(T,csr[4],csr[4])
    for i = 1:npts
        trowg = mat[:,:,i]
        tgk = diagm(trowg[:])
        tgl[find(LKc),find(LKc)] = tgk
        tgm[find(LKc),find(LKr)] = tgk
        tgr[find(LKr),find(LKr)] = tgk
        gl[:,:,i] = tgl[Uc,Uc]
        gm[:,:,i] = tgm[Uc,Ur]
        gr[:,:,i] = tgr[Ur,Ur]
     end
    return gl,gm,gr
end

function _unwrapg(rowg::FRD,blk::AbstractMatrix)
    gl,gm,gr = _unwrapg(rowg.ResponseData,blk)
    gl = frd(gl, rowg.Frequency, rowg.Ts; TimeUnit = rowg.TimeUnit)
    gm = frd(gm, rowg.Frequency, rowg.Ts; TimeUnit = rowg.TimeUnit)
    gr = frd(gr, rowg.Frequency, rowg.Ts; TimeUnit = rowg.TimeUnit)
    return gl,gm,gr
end

function LOCALunwrap(blk::AbstractMatrix)
    if length(blk[1,:]) != 2 || any(abs.(round.(real(blk))-blk) .> 1e-6)
        error(@tr("BLK is invalid"))
    elseif !any(round.(real(blk[:,1])) .!= 0) || any(isnan.(abs.(blk)))
        error(@tr("BLK is invalid"))
    else
        blk = round.(real(blk))
    end
    for ii = 1:length(blk[:,1])
        if blk[ii,:] == [1,0]
           blk[ii,:]  = [1,1] 
        elseif blk[ii,:] == [-1,1] 
            blk[ii,:]  = [-1,0] 
        elseif blk[ii,:] == [-1,-1]
            blk[ii,:] = [-1,0]
        end
    end
    if any(blk[:,2] .< 0)
        error(@tr("BLK is invalid"))
    elseif any(blk[:,2] .!= 0 .&& blk[:,1] .< 0)
        error(@tr("Real FULL blocks not allowed"))
    elseif any(abs.(blk) .> 500)
        error(@tr("No blocks larger than 500, please"))
    end
    Or,Oc,Ur,Uc,K,I,J = reindex(blk)
    Kc,Kr,Ic,Ir,Jc,Jr,Fc,Fr,kc,kr,ic,ir,jc,jr,fc,fr,sc,sr,csc,csr,
    csF,nK,nI,nJ,nF,nc,nr,kcK,icI,jcJ,jrJ,fcF = rubind(K,I,J)

    dmask = fcF'*fcF
    wd = sum(dmask) + nJ
    wdf = sum(dmask)
    wg  = sum(K)
    pmask = jrJ'*jcJ
    wp = sum(pmask) + nF
    wps = nF

    LKc = logical(Kc)
    LKr = logical(Kr)
    LFc = logical(Fc) 
    LFr = logical(Fr)
    LJc = logical(Jc) 
    LJr = logical(Jr)

    Ldmask = logical(dmask) 
    Lpmask = logical(pmask)
    return Or,Oc,Ur,Uc,Kc,Kr,Jc,Jr,Fc,Fr,csc,csr,nJ,nF,jcJ,jrJ,fcF,wd,wdf,wg,wp,wps,LKc,LKr,LFc,LFr,LJc,LJr,Ldmask,Lpmask
end

function _LMIunwrapdg(rowd::AbstractArray{T},rowg::AbstractArray{T},blk::AbstractMatrix,bnds::AbstractArray) where {T}
    tblk = abs.(blk)
    idx = find(tblk[:,2] .== 0)
    tblk[idx,2] = tblk[idx,1]
    rcdim = sum(tblk, dims=1)
    Nr = rcdim[2]
    Nc = rcdim[1]

    szmD = size(rowd)
    exdD = length(szmD) == 2 ? Int[] : szmD[3:end]
    szmG = size(rowg)
    exdG = length(szmG) == 2 ? Int[] : szmG[3:end]
    szmB = size(bnds)
    exdB = length(szmB) == 2 ? Int[] : szmB[3:end]
    if isequal(exdD,exdG) && isequal(exdD,exdB)
       npts = prod(exdD)
       exd = exdD
       matD = reshape(rowd,szmD[1],szmD[2],npts)
       matG = reshape(rowg,szmG[1],szmG[2],npts)
       matB = reshape(bnds[1,1,:],1,1,npts)
    else
       error(@tr("Corrupt D/G/BNDS data."))
    end
    Dr = isempty(exd) ? zeros(T, Nr, Nr) : zeros(T, Nr, Nr, exd)
    Dc = isempty(exd) ? zeros(T, Nc, Nc) : zeros(T, Nc, Nc, exd)
    Grc = isempty(exd) ? zeros(T, Nr, Nc) : zeros(T, Nr, Nc, exd)
    Gcr = isempty(exd) ? zeros(T, Nc, Nr) : zeros(T, Nc, Nr, exd)

    for i = 1:npts
        Dr[:,:,i],Dc[:,:,i],Grc[:,:,i],Gcr[:,:,i] = ynftdam2(matD[1,:,i]',matG[1,:,i]',blk,matB[1,:,i]')
    end
    return Dr,Dc,Grc,Gcr
end

function _LMIunwrapdg(rowd::FRD,rowg::FRD,blk::AbstractMatrix,bnds::FRD) 
    Dr,Dc,Grc,Gcr = _LMIunwrapdg(rowd.ResponseData, rowg.ResponseData, blk, bnds.ResponseData) 
    Dr = frd(Dr, rowd.Frequency, rowd.Ts, TimeUnit = rowg.TimeUnit)
    Dc = frd(Dc, rowd.Frequency, rowd.Ts, TimeUnit = rowg.TimeUnit)
    Grc = frd(Grc, rowd.Frequency, rowd.Ts, TimeUnit = rowg.TimeUnit)
    Gcr = frd(Gcr, rowd.Frequency, rowd.Ts, TimeUnit = rowg.TimeUnit)
    return Dr,Dc,Grc,Gcr
end

function reindex(blk::AbstractMatrix)
    if length(blk) == 0
        return Int[], Int[], Int[], Int[], Int[], Int[], Int[]
    end
    b = blk
    ab = abs.(b)
    fb = hcat(b[:,2] .== 0 .&& b[:,1] .< 0, b[:,2] .== 0 .&& b[:,1] .> 0, b[:,2] .> 0, 1 .+ (b[:,2].>0))
    #	real/rep		complex/rep	complex/full	complex()
    Ir1 = Int[]
    Ir2 = Int[]
    Ir3 = Int[]
    Ic1 = Int[]
    Ic2 = Int[]
    Ic3 = Int[]
    Lfb = fb
    for ii = 1:length(b[:,2])
        oner = ones(ab[ii,1],1)
        onec = ones(ab[ii,fb[ii,4]],1)
        Ir1 = [Ir1; oner*fb[ii,1]]
        Ir2 = [Ir2; oner*fb[ii,2]]
        Ir3 = [Ir3; oner*fb[ii,3]]
        Ic1 = [Ic1; onec*fb[ii,1]]
        Ic2 = [Ic2; onec*fb[ii,2]]
        Ic3 = [Ic3; onec*fb[ii,3]]
    end
    K = fb[:,1] == 0 ? Int[] : ab[logical(Lfb[:,1]),1]
    I = fb[:,2] == 0 ? Int[] : b[logical(Lfb[:,2]),1]
    J = fb[:,3] == 0 ? Int[] : b[logical(Lfb[:,3]),:]*[1;0.001]
    
    Or = [find(Ir1); find(Ir2); find(Ir3)]
    Oc = [find(Ic1); find(Ic2); find(Ic3)]
    Ur = sortperm(Or)
    Uc = sortperm(Oc)

    return Or,Oc,Ur,Uc,K,I,J
end

function rubind(K::AbstractVector,I::AbstractVector,J::AbstractVector)
    K = K[:]            
    I = I[:]             
    J = J[:]
    nK = length(K)     
    nI = length(I)        
    nJ = length(J)

    rJ = round.(Int,J)
    cJ = round.(Int,1000*(J-rJ))

    nc   = [sum(K); sum(I); sum(cJ)]  
    csc  = [0; cumsum(nc)]
    nr   = [sum(K); sum(I); sum(rJ)]  
    csr  = [0; cumsum(nr)]
    csK  = [0; cumsum(K)]
    csI  = [0; cumsum(I)] .+ csc[2]
    csJc = [0; cumsum(cJ)] .+ csc[3]
    csJr = [0; cumsum(rJ)] .+ csr[3]
    
    #       initialization of index matrices
    Kc = zeros(Int,1,csc[4]);                 
    Ic = zeros(Int,1,csc[4]);   
    Jc = zeros(Int,1,csc[4]);  
    Kr  = zeros(Int,1,csr[4]);               Ir = zeros(Int,1,csr[4]);        Jr = zeros(Int,1,csr[4]);
    kc  = zeros(Int,nK,csc[4]);              kr  = zeros(Int,nK,csr[4])
    ic  = zeros(Int,nI,csc[4]);              ir  = zeros(Int,nI,csr[4])
    jc  = zeros(Int,nJ,csc[4]);              jr  = zeros(Int,nJ,csr[4])
    ffc = zeros(Int,csc[3],csc[4]);          ffr = zeros(Int,csr[3],csr[4])

    #       putting ones in the index matrices
    Kc[csc[1]+1:csc[1+1]] = ones(Int,nc[1])
    Kr[csr[1]+1:csr[1+1]] = ones(Int,nr[1])
    Ic[csc[2]+1:csc[2+1]] = ones(Int,nc[2])
    Ir[csr[2]+1:csr[2+1]] = ones(Int,nr[2])
    Jc[csc[3]+1:csc[3+1]] = ones(Int,nc[3])
    Jr[csr[3]+1:csr[3+1]] = ones(Int,nr[3])
    for k = 1:nK             
        kr[k,csK[k]+1:csK[k+1]] = ones(Int,K[k])
        kc[k,csK[k]+1:csK[k+1]] = ones(Int,K[k])
    end
    for i = 1:nI             
        ir[i,csI[i]+1:csI[i+1]] = ones(Int,I[i])
        ic[i,csI[i]+1:csI[i+1]] = ones(Int,I[i])
    end
    for j = 1:nJ          
        jr[j,csJr[j]+1:csJr[j+1]] = ones(Int,rJ[j])
        jc[j,csJc[j]+1:csJc[j+1]] = ones(Int,cJ[j])
    end
    kcK = nK > 0 ? kc[:,find(logical(Kc))] : Int[]
    jcJ = nJ > 0 ? jc[:,find(logical(Jc))] : Int[]
    jrJ = nJ > 0 ? jr[:,find(logical(Jr))] : Int[]
    icI = nI > 0 ? ic[:,find(logical(Ic))] : Int[]

    if (nK+nI)>0
       ffc[1:csc[3],1:csc[3]] = eye(csc[3])
       ffr[1:csr[3],1:csr[3]] = eye(csr[3])
    end
    
    sc = [ffc; jc]
    sr  = [ffr; jr]
    fc = [kc; ic]
    fr = [kr; ir]
    nF = nK + nI
    Fc = Kc + Ic
    Fr  = Kr + Ir
    csF = [0; cumsum([K;I])]
    fcF = nF > 0 ? fc[:,find(logical(Fc))] : Int[]

    return Kc,Kr,Ic,Ir,Jc,Jr,Fc,Fr,kc,kr,ic,ir,jc,jr,fc,fr,sc,sr,csc,csr,csF,
    nK,nI,nJ,nF,nc,nr,kcK,icI,jcJ,jrJ,fcF
end

function ynftdam2(rowd::AbstractArray{T},rowg::AbstractArray{T},blk::AbstractMatrix,beta::AbstractArray) where {T}
    nblk = size(blk,1)
    blkp = ptrs(abs.(blk))
    mcolp = blkp[:,1]
    mrowp = blkp[:,2]
    nc = mcolp[nblk+1]-1
    nr = mrowp[nblk+1]-1
    (dl,dr),(gl,gm,gr) = _mussvunwrap(rowd,rowg,blk;nargout=5)
    dar = zeros(T,nr,nr)
    dac = zeros(T,nc,nc)
    garc = zeros(T,nr,nc)
    gacr = zeros(T,nc,nr)
    for i = 1:nblk
        if blk[i,1] < -1 && blk[i,2] == 0
            bd = -blk[i,1]
            dyn = dl[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1]
            gyn = gl[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1]
            gscl = diag(gyn)
            dx = diagm(ones(bd)./sqrt.(sqrt.(ones(bd) + gscl.*gscl)))*dyn
            u,s,v = svd(dx)
            hx = v*diagm(s)*v'
            ux = u*v'
            df = hx
            gf = ux'*gyn*ux
            da = df'*df
            ga = beta.*df'*gf*df
            dac[mcolp[i]:mcolp[i+1]-1,mcolp[i]:mcolp[i+1]-1] = da
            dar[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1] = da
            gacr[mcolp[i]:mcolp[i+1]-1,mrowp[i]:mrowp[i+1]-1] = ga
            garc[mrowp[i]:mrowp[i+1]-1,mcolp[i]:mcolp[i+1]-1] = ga
        elseif blk[i,1] > 1 && blk[i,2] == 0
            bd = blk[i,1]
            dyn = dl[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1]
            dx = dyn
            u,s,v = svd(dx)
            # u*v"*v*s*v" = dx
            hx = v*diagm(s)*v'
            df = hx
            da = df'*df
            dac[mcolp[i]:mcolp[i+1]-1,mcolp[i]:mcolp[i+1]-1] = da
            dar[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1] = da
        elseif blk[i,1] > 0 && blk[i,2] > 0
            rdim = blk[i,2]    # col of delta, row of M
            cdim = blk[i,1]    # row of delta, col of M
            dyn = dl[mrowp[i],mrowp[i]]
            dx = dyn
            hx = abs.(dx)
            df = hx
            da = df*df
            dac[mcolp[i]:mcolp[i+1]-1,mcolp[i]:mcolp[i+1]-1] = da*eye(cdim)
            dar[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1] = da*eye(rdim)
        elseif  blk[i,1] == 1 && blk[i,2] == 0
            rdim = 1
            cdim = 1
            dyn = dl[mrowp[i],mrowp[i]]
            dx = dyn
            hx = abs.(dx)
            df = hx
            da = df*df
            dac[mcolp[i]:mcolp[i+1]-1,mcolp[i]:mcolp[i+1]-1] = da*eye(cdim)
            dar[mrowp[i]:mrowp[i+1]-1,mrowp[i]:mrowp[i+1]-1] = da*eye(rdim)
        elseif  blk[i,1] == -1
            bd = -blk[i,1]
            dyn = dl[mrowp[i],mrowp[i]]
            gyn = gl[mrowp[i],mrowp[i]]
            gscl = gyn
            dx = dyn / sqrt.(sqrt.(1 .+ gscl*gscl))
            hx = abs.(dx)
            ux = dx/hx
            df = hx
            gf = ux'*gyn*ux
            da = df'*df
            ga = beta.*df'*gf*df
            dac[mcolp[i]:mcolp[i], mcolp[i]:mcolp[i]] .= da
            dar[mrowp[i]:mrowp[i], mrowp[i]:mrowp[i]] .= da
            gacr[mcolp[i]:mcolp[i], mrowp[i]:mrowp[i]] .= ga
            garc[mrowp[i]:mrowp[i], mcolp[i]:mcolp[i]] .= ga
        end
    end
    return dar,dac,garc,gacr
end

function ptrs(blk::AbstractMatrix{T}) where {T}
    nblk = size(blk,1)
    blkp = zeros(T,nblk+1,2)
    blkp[1,:] = [1,1]
    for i = 1:nblk
        if blk[i,2] == 0
            blkp[i+1,:] = blkp[i,:] + [blk[i,1], blk[i,1]]
        else
            blkp[i+1,:] = blkp[i,:] + blk[i,:]
        end
    end
    return blkp
end
