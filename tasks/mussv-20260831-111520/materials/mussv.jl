function mussv(matin::AbstractArray{T},blk::AbstractMatrix{<:Integer},opt::String="",fixedBlkIdx::AbstractVecOrMat{<:Integer}=zeros(Int,0,1)) where {T<:Number}
    blk = blkstruct2N2(blk)
    opt = join([opt,"s"])                           # 强制忽略进度信息
    bnds,rowd,rowp,rowg,sens,blk = _mussvcalc2(matin,blk,opt,fixedBlkIdx)
    Info = MussvInfo(bnds,rowd,rowp,rowg,sens,blk)
    return bnds,Info
end

function mussv(matin::FRD,blk::AbstractMatrix{<:Integer},opt::String="",fixedBlkIdx::AbstractVecOrMat{<:Integer}=zeros(Int,0,1))
    blk = blkstruct2N2(blk)
    bnds,rowd,rowp,rowg,sens,blk = _mussvcalc2(matin.ResponseData,blk,opt,fixedBlkIdx)
    bnds = frd(bnds,matin.Frequency,matin.Ts;FrequencyUnit = matin.FrequencyUnit)
    sens = frd(sens,matin.Frequency,matin.Ts;FrequencyUnit = matin.FrequencyUnit)
    rowd = frd(rowd,matin.Frequency,matin.Ts;FrequencyUnit = matin.FrequencyUnit)
    rowp = frd(rowp,matin.Frequency,matin.Ts;FrequencyUnit = matin.FrequencyUnit)
    rowg = frd(rowg,matin.Frequency,matin.Ts;FrequencyUnit = matin.FrequencyUnit)
    Info = MussvInfo(bnds,rowd,rowp,rowg,sens,blk)
    return bnds,Info
end

function blkstruct2N2(blk::AbstractMatrix{<:Integer},allowsubs::Integer=0)
    fz = sum(abs.(blk),dims=2)
    locz = find(fz .== 0)
    if !isempty(locz)
       blk = blk[1:end .!= locz, :]
    end
    return blk 
end

function _mussvcalc2(matin::AbstractArray{T},blk::AbstractMatrix{<:Integer},opt::String,fixedBlkIdx::AbstractVecOrMat{<:Integer}) where {T<:Number}
    @ccall_check_func_lic :TyRobustControl
    displaywarnings = contains(opt,'d')
    fastupper = contains(opt,'f')
    bestupper = contains(opt,'a')
    bestuppernoscaling = contains(opt,'n')
    initialize = contains(opt,'i')
    multiplelower = contains(opt,'m')
    multiplelowertimes = multiplelower ? _goptvl(opt,'m',1,1) : 0

    silent = contains(opt,'s')
    decreaselower = contains(opt,'x')
    decreaselowerto2 = contains(opt,'U')
    increaselower = contains(opt,'t')
    backup = contains(opt,'b')
    runmuwcglb = contains(opt,'g')
    runspi = contains(opt,'p')
    if bestupper
        @warn "The 'a' LMI upper-bound option is not implemented; falling back to gradient descent."
        bestupper = false
    end
    if decreaselowerto2
        CNTMAX = 2
    elseif decreaselower
        CNTMAX = 50
    else
        CNTMAX = 100
    end
    szm = size(matin)
    exd = szm[3:end]

    npts = round(Int,prod(exd))
    # make N-D into 3-D
    mat = reshape(matin,szm[1],szm[2],npts)

    Mr = szm[1]
    Mc = szm[2]

    size(blk,2) == 2 || error(@tr("BLK must be an N x 2 integer matrix."))
    nblk = size(blk,1)
    for ii = 1:nblk
        if blk[ii,:] == [1,0]
           blk[ii,:]  = [1,1] 
        elseif blk[ii,:] == [-1,1] 
            blk[ii,:]  = [-1,0]
        elseif blk[ii,:] == [-1,-1]
            blk[ii,:] = [-1,0]
        end
    end
    # Get indices from blk2idx plus a few other indices/masks needed for mu
    # Also grab indices for real blocks only and for complex blocks only
    index,blk = _mkBlkData(blk,fixedBlkIdx)
    # if bestupper
    #     dtol = 1e-4
    #     DGLMI =  rctutil.DGLMIsys(index,fixedBlkIdx);
    #     DGLMI.dtol = dtol;
    #     DGLMI.LMIopt = [1e-2 0 1/dtol 5 1];
    #     index.allDGlmi = DGLMI;
    # end
    index["allreal"]["realidx"],_ = _mkBlkData(index["allreal"]["realblk"])
    index["allcomp"]["compidx"],_ = _mkBlkData(index["allcomp"]["compblk"])
    ridxm = index["ridxm"]
    cidxm = index["cidxm"] 
    # Check compatibility of block and matrix dimensions
    if (index["rdimm"] != Mr || index["cdimm"] != Mc)
        error(@tr("The matrix dimension does not match the BLK dimension."))
    end
    # Set lower bound opt structure for pure real problems
    # Use to increase # of power iters if matrix data is real
    if index["allcomp"]["num"] == 0
        CNTMAX = 300
        if !(runspi || decreaselower || decreaselowerto2 || increaselower || runmuwcglb)
            runmuwcglb = true
        end
    else
        runspi = true
    end
    # Revisit this logic if/when we implement FV version of muwcglb.
    hasFixedBlock = !isempty(fixedBlkIdx)
    if hasFixedBlock
        # At this point, No gain-based for FV problems
        runmuwcglb = false
        runspi = true
    end
    # Set # of tries for muwcglb
    if runmuwcglb
        notfoundval = min(max(1,ceil(nblk/4)),5)
        GBLBoptval = _goptvl(opt,"g",1,notfoundval)
        Ntry = 10+10*GBLBoptval
    end
    if index["allcomp"]["num"] == 0 && displaywarnings
        @warn @tr("When there is only real parameter uncertainty, the μ lower bound may be inaccurate.")
    end

    wp = sum(index["masks"]["DeltaFull_mask"]) + index["allrep"]["num"]
    wd = sum(index["masks"]["Drep_mask"]) + index["full"]["num"]
    wg = sum(index["allreal"]["repeated"])
    bnds = zeros(1,2,exd...)                   # 输入为 FRD 类型时，矩阵的维度对应输出和输入的个数
    rowp = zeros(T,1,wp,exd...)
    rowd = zeros(T,1,wd,exd...)
    rowg = zeros(T,1,wg,exd...)
    sens = zeros(1,nblk,exd...)
    silent || print(@tr("Points completed : "))

    rng = MT19937ar()
    lptxt = ""
    fnpts = 10*floor(npts/10)
    deltareal = Int[]
    bprev = zeros(T,Mc)
    wprev = zeros(T,Mc)
    for ii = 1:npts
        M = mat[:,:,ii]  
        if !bestuppernoscaling
            dMd,Dr_os,Dc_os = _osbal(M,index)
            Dc_os = inv(Dc_os)
        else
            dMd = M
            Dr_os = eye(Mr)
            Dc_os = eye(Mc)
        end
        # Scale Data and Compute Initial Upper Bound
        # scale = maximum(abs.(dMd))/5
        # if scale < 10*eps()
        #     scale = 1
        # else
        #     dMd = dMd/scale
        # end
        # _,ss,vv = svd(dMd)
        # ub = ss[1]

        scale = maximum(abs.(dMd))/5
        (scale >= 10*eps()) || (scale = 1)
        dMd[index["FVidx"][:VaryRows],:]  = dMd[index["FVidx"][:VaryRows],:]/sqrt(scale)
        dMd[:,index["FVidx"][:VaryCols]]  = dMd[:,index["FVidx"][:VaryCols]]/sqrt(scale)
        _,svDMD,vv = svd(dMd)

        if hasFixedBlock
            FixedCols = index["FVidx"][:FixedCols]
            VaryCols = index["FVidx"][:VaryCols]
            DcF = zeros(Int,Mc,Mc)
            DcV = zeros(Int,Mc,Mc)
            DcF[FixedCols,FixedCols] = eye(length(FixedCols))
            DcV[VaryCols,VaryCols] = eye(length(VaryCols))
            A = dMd'*dMd - DcF
            B = DcV
            evals = eigvals(A, B)
            finite_evals = real(evals[isfinite.(evals)])
            if isempty(finite_evals)
                # A singular fixed/vary pencil can have no finite generalized
                # eigenvalues. Start conservatively and let _DGinit construct
                # a finite skewed-mu upper-bound certificate below.
                ub = Inf
            else
                ubsq = 1.0001 * max(
                    maximum(finite_evals), zero(eltype(finite_evals))
                )
                ub = maximum(real(eigvals(A - ubsq * B))) <= 0 ? sqrt(ubsq) : Inf
            end
        else
            ub = svDMD[1,1]
        end
        Dr = eye(Mr)
        Dc = eye(Mc)
        Gcr = zeros(Int,Mc,Mr)
        if runspi
            if initialize || ii==1
                # initialize lower bound with no previous info
                bstart = vv[:,1]
                wstart = copy(bstart)
            else
                # initialize lower bound with previous result
                bstart = copy(bprev)
                wstart = copy(wprev)
            end
            if index["allcomp"]["num"] == 0 && isreal(dMd)
                # Increase # of power iterations if pure real unc/pure real data
                lb,Delta,b,w = _mmupiter(dMd,index,bstart,wstart,CNTMAX)
            else
                lb,Delta,b,w = _mmupiter(dMd,index,bstart,wstart,CNTMAX)
            end
        else
            lb = 0
            Delta = zeros(Mc,Mr)
            repc = index["allrep"]["allcols"]
            repr = index["allrep"]["allrows"]
            Delta[repc,repr] = 1e50*eye(length(repc))
            fullc = index["full"]["allcols"]
            fullr = index["full"]["allrows"]
            Delta[fullc,fullr] =  1e50 * index["masks"]["DeltaFull_mask"]
        end

        if index["allreal"]["num"] > 0 &&
           isfinite(ub) &&
           ub > 1.005*max(lb,10*eps())

            ubFUB,DrFUB,DcFUB,GcrFUB = _mufastub(dMd,index,ub,lb)

            if ubFUB < ub
                ub, Dr, Dc, Gcr = ubFUB, DrFUB, DcFUB, GcrFUB
            end
        end

        # -------------------------Fast Upper Bound-------------------------
        if !fastupper && !bestupper && ub > 1.005*max(lb,10*eps())
            # Gradient Descent Upper Bound
            if isinf(ub)
                # DGinit = _DGinit(dMd,index,"G")
                ub,Dr,Dc,Gcr = _DGinit(dMd,index,"G")
            end
            ub0, Dr0, Dc0, Gcr0 = copy(ub), copy(Dr), copy(Dc), copy(Gcr)
            stalled_passes = 0
            descent_passes = hasFixedBlock ? 15 : 1
            for _ = 1:descent_passes
                ubtry,Drtry,DcFtry,DcVtry,Gcrtry = _mudescentub(
                    dMd,index,ub,Dr,Dc,Gcr,
                )
                Dctry = DcFtry+DcVtry
                bound_tolerance = sqrt(eps(float(one(lb))))*max(lb,one(lb))
                valid_upper = isfinite(ubtry) && ubtry+bound_tolerance >= lb
                if valid_upper && ubtry <= ub*(1+1e-8)
                    improvement = ub-ubtry
                    ub,Dr,Dc,Gcr = max(ubtry,lb),Drtry,Dctry,Gcrtry
                    stalled_passes = improvement <= 1e-8*max(ub,one(ub)) ? stalled_passes+1 : 0
                else
                    stalled_passes += 1
                end
                stalled_passes >= 2 && break
            end
            if ub > ub0
                ub, Dr, Dc, Gcr = ub0, Dr0, Dc0, Gcr0
            end

            # LMI Upper Bound: Use Hot start
            # if bestupper && ub > 1.005*max(lb,10*eps())
            #     ub,Dr,_,Gcr = _mulmiub(dMd,index,Dr,Dc,Gcr,ub)
            # end
        end
        if runspi
            for jj = 1:multiplelowertimes
                bstart = complex.(rand(rng,Mc,1),rand(rng,Mc,1))
                bstart = bstart/(opnorm(bstart) + 10*eps())
                wstart = complex.(rand(rng,Mc,1),rand(rng,Mc,1))
                wstart = wstart/(opnorm(wstart) + 10*eps())
                if index["allcomp"]["num"] == 0 && isreal(dMd)
                    lbtry,Deltatry,btry,wtry = _mmupiter(dMd,index,bstart,wstart,CNTMAX)
                else
                    lbtry,Deltatry,btry,wtry = _mmupiter(dMd,index,bstart,wstart,CNTMAX)
                end
                if lbtry > lb
                    lb = lbtry
                    Delta = Deltatry
                    b = btry
                    w = wtry
                end
            end
            bprev = copy(b)
            wprev = copy(w)
        end

        # -------------------------Lower Bound-------------------------
        # if runmuwcglb && index["allreal"]["num"] > 0 && ub > 100*eps()
        #     lbtry,Deltatry,deltareal = _muwcglb(dMd,index,deltareal,[ub,lb],rng,Ntry)
        #     if lbtry > lb
        #        lb = lbtry
        #        Delta = Deltatry
        #     end
        # end
        # -------------------------Unscale and prepare outputs-------------------------
        ub = max(ub,1e-3)
        ub = ub*scale
        lb = lb*scale
        # Delta = Delta/scale
        Delta[index["FVidx"][:VaryCols], index["FVidx"][:VaryRows]] = Delta[index["FVidx"][:VaryCols], index["FVidx"][:VaryRows]]/scale
        normM = opnorm(M)
        if (ub < normM) || (hasFixedBlock && isfinite(ub))
            # Dr = Dr_os'*Dr*Dr_os
            Gcr = scale*(Dc_os'*Gcr*Dr_os)
            Dcell = Vector{Any}(undef, nblk)  
            Gcell =  Vector{Any}(undef, nblk)  
            for i=1:nblk
                if blk[i,2] == 0
                    rptr = ridxm[i]:(ridxm[i+1]-1)
                    cptr = cidxm[i]:(cidxm[i+1]-1)
                else
                    rptr = ridxm[i]:ridxm[i]
                    cptr = cidxm[i]:cidxm[i]
                end
                Gcell[i] = Gcr[cptr,rptr]
                if any(i.==fixedBlkIdx)
                    DrBlk = scale*Dr[rptr,rptr]
                else
                    DrBlk = Dr[rptr,rptr]
                end
                Dr_osBlk = Dr_os[rptr,rptr]
                d,u,_ = schur(DrBlk)
                d = sqrt.(diag(d))
                _,s,v = svd(lrscale(u'*Dr_osBlk,d,Int[]))
                Dcell[i] = v*diagm(s)*v'
            end
            trowd,trowg = _ami2ynrow(Dcell,Gcell,blk,ub,true)
        else
            hasFixedBlock || (ub = normM)
            trowd,trowg = _sigmaub(blk)
        end
        bnds[1,:,ii] = [ub lb]
        # Store Delta as rep reals, rep comp, complex full
        trowp = zeros(eltype(Delta),1,wp)
        cnt = 1
        for i = 1:nblk
            if blk[i,1] < 0 && blk[i,2] == 0
                rptr = ridxm[i]
                cptr = cidxm[i]
                trowp[cnt] = Delta[cptr,rptr]
                cnt = cnt + 1
            end
        end
        for i = 1:nblk
            if blk[i,1] > 0 && blk[i,2] == 0
               rptr = ridxm[i]
               cptr = cidxm[i]
               trowp[cnt] = Delta[cptr,rptr]
               cnt = cnt + 1
            end
        end
        # ridxm = index["full"]["allrows"]
        # cidxm = index["full"]["allcols"]
        tmp = Delta[index["full"]["allcols"],index["full"]["allrows"]]
        trowp[index["allrep"]["num"]+1:end] = tmp[index["masks"]["DeltaFull_mask"] .!= 0]
        (wg != 0)  && (rowg[1,:,ii] = trowg)
        rowd[1,:,ii] = trowd
        if lb > 0
            rowp[1,:,ii] = trowp
        end

        # Sensitivity calculation
        tdl,tdr = _mussvunwrap(trowd,blk;nargout=2)
        sm = tdl*M/tdr
        # ridxm = index["ridxm"]
        # cidxm = index["cidxm"]
        if nblk == 1
           sens[1,1,ii] = 1
        else
            for ib=1:nblk
                sensr = sm[ridxm[ib]:ridxm[ib+1]-1,vcat(1:cidxm[ib]-1,cidxm[ib+1]:Mc)]
                sensc = sm[vcat(1:ridxm[ib]-1,ridxm[ib+1]:Mr),cidxm[ib]:cidxm[ib+1]-1]
                sens[1,ib,ii] = opnorm(sensr) + opnorm(sensc)
            end
        end
        if !silent
            print(repeat('\b',length(lptxt)))
            lptxt = @sprintf "%d/%d" ii npts
            print(lptxt)
        end
    end
    if !silent && backup
        nonewline = repeat('\b',length(lptxt))
        print(nonewline)
    elseif !silent
        print("\n")
    end
    bnds[1,1,:] = (1+5e-7)*bnds[1,1,:]
    return bnds,rowd,rowp,rowg,sens,blk
end

function _osbal(M::AbstractMatrix{T},index::Dict,opt::String="f") where {T<:Number}
    nrep = index["allrep"]["num"]
    nfull = index["full"]["num"]
    reprows = index["allrep"]["allrows"]
    repcols = index["allrep"]["allcols"]
    repeated  = index["allrep"]["repeated"]
    repidx =  cumsum([1; repeated],dims=1)

    Mr,Mc = size(M)
    nd = length(reprows)+nfull
    sr  = index["masks"]["sr"]
    sc  = index["masks"]["sc"]
    afullidx = index["masks"]["afullidx"]

    # Stopping Conditions
    if opt == "f" && nrep != 0
        userot = true
        mxrotiter = 10
    else
        userot = false
        mxrotiter = 0
    end
    reltol = 2e-3
    mxosbiter = 30
    reltol2 = 1e-4 

    # Initialize
    dMd = 1.0*M
    dr = 1.0*eye(T,Mr,Mr)
    dci = 1.0*eye(T,Mc,Mc)
    drot = 1.0*eye(T,length(reprows))
    dvec = ones(1,nd)
    rotcnt = 0
    cost = opnorm(dMd,2)
    oldcost = max(2*cost,10*eps())
    go = true

    while go && (rotcnt <= mxrotiter) && (reltol*oldcost < (oldcost-cost))
        rotcnt = rotcnt + 1
        if userot
            a = dMd[reprows,:]*dMd[reprows,:]'-dMd[:,repcols]'*dMd[:,repcols];
            for i = 1:nrep
                idx = repidx[i]:(repidx[i+1]-1)
                drot[idx,idx],_ = svd(a[idx,idx])
            end
            dr[reprows,:] = drot'* dr[reprows,:]
            dci[:,repcols] = dci[:,repcols]*drot
            dMd[reprows,:] = drot'*dMd[reprows,:]
            dMd[:,repcols] = dMd[:,repcols]*drot
        end	
        a = sr*real(conj(dMd).*dMd)*sc 
        for i1 = 1:nfull
            ridx = index["full"]["rows"][i1]
            afullr = afullidx[i1]
            for i2 = 1:nfull
                cidx = index["full"]["cols"][i2]
                afullc = afullidx[i2]
                a[afullr,afullc] = opnorm([dMd[ridx,cidx];;])^2
            end
        end
        a = a - diagm(diag(a))		
        d = ones(1,nd)
        cost2 = sum(sum(a))			
        oldcost2 = max(2*cost2,10*eps())
        itcnt = 0
        astart = a
        while (itcnt < mxosbiter) && reltol2*oldcost2 < (oldcost2-cost2)      
            sa = max.(sum(a,dims=1),10*eps())
            sat = max.(sum(a',dims=1),10*eps())
            d = d.*sqrt.(sqrt.(sa./sat))
            d = min.(max.(d,1e-8),1e8)   
            a = astart.*(d'*(1 ./d))
            itcnt = itcnt+1
            oldcost2 = max(cost2,10*eps())	
            cost2 = sum(sum(a))
        end     
       
        d = sqrt.(d/d[1,1])
        dvec = dvec.*d
            
        drvec = diag(sr'*diagm(d[:])*sr)
        dcivec = diag(sc*diagm(1 ./d[:])*sc')'

        drmat = repeat(drvec,1,Mc)
        dcimat = repeat(dcivec,Mr,1)
        dMd = drmat.*dMd.*dcimat

        drmat = repeat(drvec,1,Mr)
        dcimat = repeat(dcivec,Mc,1)
        dr  = drmat.*dr
        dci = dci.*dcimat
        
        oldcost = max(cost,10*eps())
        cost = opnorm(dMd,2)
            
        dcond = maximum(dvec)/max(minimum(dvec),10*eps())
        if dcond > 1e10
            go = false
        end
    end
    return dMd,dr,dci
end

function _mmupiter(M::AbstractMatrix{T},index::Dict,bstart::VecOrMat{<:Number}=Int[],wstart::VecOrMat{<:Number}=Int[],CNTMAX::Integer=50) where {T<:Number}
    ismissing(CNTMAX) && (CNTMAX = 50)
    stol = 1e-7
    step = size(M,2)/4
    # !ismissing(opt) && (CNTMAX = opt.CNTMAX)
    VaryRows = index["FVidx"][:VaryRows]
    VaryCols = index["FVidx"][:VaryCols]
    fixedBlkIdx = index["FVidx"][:fixedBlkIdx]
    FixedRows = index["FVidx"][:FixedRows]
    FixedCols = index["FVidx"][:FixedCols]
    FixedUnionRealCols = index["FVidx"][:FixedUnionRealCols]
    FixedUnionRealRows = index["FVidx"][:FixedUnionRealRows]
    VaryComplexCols = index["FVidx"][:VaryComplexCols]
    VaryComplexRows = index["FVidx"][:VaryComplexRows]
    allVary = isempty(fixedBlkIdx)
    nVR = length(VaryRows)
    nFR = length(FixedRows)
    nComplexVary = length(index["FVidx"][:VaryCIdx])
    nComplexFixed = length(index["FVidx"][:FixedCIdx])
    problemType = index["problemType"]
    Mr,Mc = size(M)
    if isempty(bstart)
        _,_,v = svd(M)   
        RNG = MT19937ar()
        b = v[:,1] + 0.01*complex.(rand(RNG,Mc,1).-0.5,rand(RNG,Mc,1).-0.5)
        bstart = b/opnorm(b)
        if allVary || Mc==1
            wstart = copy(bstart)
        else
            w = v[:,2] + 0.01*complex.(rand(RNG,Mc,1).-0.5,rand(RNG,Mc,1).-0.5)
            wstart = w/opnorm(w)
        end  
    end    
    newz = zeros(T,Mr,1)
    newb = zeros(T,Mc,1)
    z = zeros(T,Mr,1)
    a = zeros(T,Mr,1)
    b = copy(bstart)
    w = copy(wstart)
    newb = copy(b)
    # Get indices for real scalars, complex scalars, and complex full blocks
    # nrepc = index["allcomp"]["num"]
    # compr = index["allcomp"]["allrows"]
    # compc = index["allcomp"]["allcols"]

    nreal = index["allreal"]["num"]
    realr = index["allreal"]["allrows"]
    realc = index["allreal"]["allcols"]

    nrepc = index["repcomp"]["num"]
    repcr = index["repcomp"]["allrows"]
    repcc = index["repcomp"]["allcols"]

    nfull = index["full"]["num"]
    fullr = index["full"]["allrows"]
    fullc = index["full"]["allcols"]
    # Get masks used to vectorize code
    real_mask = index["masks"]["real_mask"]
    repc_mask = index["masks"]["repc_mask"]
    Dfull_maskr = index["masks"]["Dfull_maskr"]
    Dfull_maskc = index["masks"]["Dfull_maskc"]
    DeltaFull_mask = index["masks"]["DeltaFull_mask"]
    # Transpose Masks once (rather than in loops)
    real_maskT = real_mask'
    repc_maskT = repc_mask'
    Dfull_maskrT = Dfull_maskr'
    Dfull_maskcT = Dfull_maskc'
    # Transpose M
    if allVary
        MT = M'
        M11 = zeros(0,0)
        M12 = zeros(0,Mc)
        M21 = zeros(Mr,0)
        M22 = M
    else
        M11 = M[FixedRows,FixedCols]
        M12 = M[FixedRows,VaryCols]
        M21 = M[VaryRows,FixedCols]
        M22 = M[VaryRows,VaryCols]
        M11s = M11'
        M12s = M12'
        M21s = M21'
        M22s = M22'
    end
    ALLREALSARESCALAR = isequal(real_mask, eye(size(real_mask)))
    ALLFULLSARESCALAR = isequal(Dfull_maskc, eye(size(Dfull_maskc))) && isequal(Dfull_maskr, eye(size(Dfull_maskr)))
    # Set up for loop
    converged = false
    cnt = 0
    qb = ones(nreal)
    lb = 0
    ascale = wscale = 1
    while !converged && cnt<CNTMAX
        cnt = cnt + 1
        if allVary
            newa = M*b
            beta1 = opnorm([newa;;]) 
            newa = newa/beta1
        else
            b1 = b[FixedCols]
            b2 = b[VaryCols]
            M11b = M11*b1
            M12b = M12*b2
            M21b = M21*b1
            M22b = M22*b2
            
            _,alpha1,newa = s4vecp(M11b,M12b,M21b,M22b)
            beta1 = 1/alpha1
            if isinf(beta1)
               ascale = opnorm(newa)
                if ascale == 0
                    ascale = 1
                end
            else
               ascale = 1
            end
            newa[[FixedRows; VaryRows]] = newa/ascale
        end 
        if beta1 < 100*eps()
            # a = newa
            break
        end
        # newa = newa/beta1
    
        if cnt == 1 
            qb = real(real_mask*( conj(b[realc]).*newa[realr] ))
        end
    
        # real blocks
        if nreal > 0
            wreal = w[realc]
            areal = newa[realr]
            breal = b[realc]
            if ALLREALSARESCALAR
                norma = abs.(areal)
                normb = abs.(breal)
                wa = conj(wreal).*areal
            else
                norma = sqrt.(real_mask*real( conj(areal).*areal ))
                normb = sqrt.(real_mask*real( conj(breal).*breal ))
                wa = real_mask*( conj(wreal).*areal )
            end
            norma = norma + (norma .<= 100*eps()*normb).*(normb .+ 100*eps())
            qz = sign.(qb).*normb./norma + step*real(wa)  
            qz = qz./max.(abs.(qz),1)
            if ALLREALSARESCALAR
                newz[realr] = qz.*wreal
            else
                newz[realr] = (real_maskT*qz).*wreal
            end
        end
        
        # repeated complex scalar blocks
        if nrepc > 0
            wrepc = w[repcc]
            arepc = newa[repcr]
            wa = repc_mask*( conj(wrepc).*arepc )
            abs_wa = abs.(wa)
            wa = (abs_wa .> 100*eps()) .* ( wa./ max.(abs_wa,100*eps()) )
            newz[repcr] = (repc_maskT*wa).*wrepc
        end
        
        # full blocks
        if nfull > 0
            wfull = w[fullc]
            afull = newa[fullr]
            if ALLFULLSARESCALAR
                norma = abs.(afull)
                normw = abs.(wfull)
            else
                norma = sqrt.(Dfull_maskr*real(conj(afull).*afull))
                normw = sqrt.(Dfull_maskc*real(conj(wfull).*wfull))
            end
            tmp = zeros(nfull,1)
            idx = find(norma .> 100*eps()*normw)
            tmp[idx] = normw[idx]./norma[idx]
            if ALLFULLSARESCALAR
                newz[fullr] = tmp.*afull
            else
                newz[fullr] = (Dfull_maskrT*tmp).*afull
            end
        end
        if allVary
            neww = MT*newz
            beta2 = opnorm(neww)
            neww = neww/beta2
        else
            z1 = newz[FixedRows]
            z2 = newz[VaryRows]
            M11sz = M11s*z1
            M21sz = M21s*z2
            M12sz = M12s*z1
            M22sz = M22s*z2

            _,alpha2,neww = s4vecp(M11sz,M21sz,M12sz,M22sz)
            beta2 = 1/alpha2
            if isinf(beta2)
               wscale = opnorm(neww)
                if wscale==0
                    wscale = 1
                end
            else
               wscale = 1
            end
            neww[[FixedCols;VaryCols]] = neww/wscale
        end
        # Update
        if beta2 < 100*eps() 
            break
        end
        
        # real blocks
        if nreal > 0
            wreal = neww[realc]
            areal = newa[realr]
            breal = b[realc]
            if ALLREALSARESCALAR
                norma = abs.(areal)
                normb = abs.(breal)
                wa = conj(wreal).*areal
            else
                norma = sqrt.(real_mask*real(conj(areal).*areal))
                normb = sqrt.(real_mask*real(conj(breal).*breal))
                wa = real_mask*( conj(wreal).*areal )
            end
            norma = norma + (norma .<= 100*eps()*normb).*(normb .+ 100*eps())
            qb = sign.(qz).*normb./norma+step*real(wa)   
            qb = qb./max.(abs.(qb),1) 
            if ALLREALSARESCALAR
                newb[realc] = qb.*areal
            else
                newb[realc] = (real_maskT*qb).*areal
            end
        end
        
        # repeated complex scalar blocks
        if nrepc>0
            wrepc = neww[repcc]
            arepc = newa[repcr]
            aw = repc_mask*(conj(arepc).*wrepc)
            abs_aw = abs.(aw)
            aw = (abs_aw .> 100*eps()).*(aw ./ max.(abs_aw,100*eps()))    
            newb[repcc] = (repc_maskT*aw).*arepc
        end
        
        # full blocks
        if nfull>0
            wfull = neww[fullc]
            afull = newa[fullr]
            if ALLFULLSARESCALAR
                norma = abs.(afull)
                normw = abs.(wfull)
            else
                norma = sqrt.(Dfull_maskr*real(conj(afull).*afull))
                normw = sqrt.(Dfull_maskc*real(conj(wfull).*wfull))   
            end
            tmp = zeros(nfull,1)
            idx = find(normw .> 100*eps()*norma)
            tmp[idx] = norma[idx]./normw[idx]
            if ALLFULLSARESCALAR
                newb[fullc] = tmp.*wfull
            else
                newb[fullc] = (Dfull_maskcT*tmp).*wfull
            end
        end
        newlb = max(beta1,beta2)
        if abs( newlb-lb ) < stol
            chng = [newb; newa; newz; neww] - [b; a; z; w]
            if maximum(abs.(chng)) < stol
                converged = true
            end
        end
            
        # Update
        lb = copy(newlb)
        a = copy(newa)
        b = copy(newb)
        z = copy(newz)
        w = copy(neww)
    end
    # Store output vectors
    bout = copy(b)
    wout = copy(w)
    lb_iter = copy(lb)
    Delta = _mkcpert(b,a,index,"dyad")
    Delta[realc,realr] =  diagm(real_maskT*qb)
    Delta[VaryCols,VaryRows] = (1/lb_iter)*Delta[VaryCols,VaryRows]

    # FixedBlocks can be <1 but can't be >1--> Don't allow fixScale to be <1.
    fixScale = maximum([1, ascale, wscale])
    Delta[FixedCols,FixedRows] = Delta[FixedCols,FixedRows]/fixScale
    if problemType in [:robstab; :robgain]
        if lb > 100*eps() && nComplexVary == 0
            if problemType == :robstab
                DeltaVary = Delta[VaryCols, VaryRows]
                Mloop99 = M11 + M12*(0.9999*DeltaVary)/(eye(nVR)-M22*(0.9999*DeltaVary))*M21
                Mloop101 = M11 + M12*(1.0001*DeltaVary)/(eye(nVR)-M22*(1.0001*DeltaVary))*M21
                n99 = opnorm(Mloop99)
                n101 = opnorm(Mloop101)
                if n99 >= 1
                    lb = 1/opnorm(0.9999*DeltaVary)
                    U,S,V = svd(Mloop99)
                    DeltaFixed = (V[:,1]*U[:,1]')/S[1]
                    Delta[FixedCols, FixedRows] = DeltaFixed
                    Delta[VaryCols, VaryRows] = 0.9999*DeltaVary
                elseif n101 < 1
                    lb = 0
                else
                    t = (1-n99)/(n101-n99)
                    vscale = 0.9999*(1-t) + 1.0001*t + 1e-5
                    Mloop = M11 + M12*(vscale*DeltaVary)/(eye(nVR)-M22*(vscale*DeltaVary))*M21
                    nrmMloop = opnorm(Mloop)
                    if nrmMloop >= 1
                       lb = 1/opnorm(vscale*DeltaVary)
                       U,S,V = svd(Mloop)
                       DeltaFixed = (V[:,1]*U[:,1]')/S[1]
                       Delta[FixedCols, FixedRows] = DeltaFixed
                       Delta[VaryCols, VaryRows] = vscale*DeltaVary
                    else
                       vscale = 1.0001
                       lb = 1/opnorm(vscale*DeltaVary)
                       U,S,V = svd(Mloop101)
                       DeltaFixed = (V[:,1]*U[:,1]')/S[1]
                       Delta[FixedCols, FixedRows] = DeltaFixed
                       Delta[VaryCols, VaryRows] = vscale*DeltaVary
                    end
                end
            else
                DeltaFixed = Delta[FixedCols, FixedRows]
                Mloop = M22 + M21*DeltaFixed/(eye(nFR)-M11*DeltaFixed)*M12
                DeltaVary = Delta[VaryCols, VaryRows]
                evl = eigvals(Mloop*DeltaVary)
                minD1 = minimum(abs.(1-evl))
                if minD1 > 1e-10
                   lb = 0
                end
            end
        elseif lb > 100*eps()
            DeltaFixedUnionReal = Delta[FixedUnionRealCols, FixedUnionRealRows]
            M11 = M[FixedUnionRealRows,FixedUnionRealCols]
            evl = eigvals(M11*DeltaFixedUnionReal)
            if any(minimum(abs.(1 .- evl),dims=2) .< 1e-10)
                Delta[VaryComplexCols, VaryComplexRows] .= 0
                lb = 1/opnorm(Delta[VaryCols,VaryRows])
            else
                R11 = length(FixedUnionRealRows)
                M12 = M[FixedUnionRealRows,VaryComplexCols]
                M21 = M[VaryComplexRows,FixedUnionRealCols]
                M22 = M[VaryComplexRows,VaryComplexCols]
                Mloop = M22 + M21*DeltaFixedUnionReal/(eye(R11)-M11*DeltaFixedUnionReal)*M12
                DeltaVaryComplex = Delta[VaryComplexCols, VaryComplexRows]
                evl = eigvals(DeltaVaryComplex*Mloop)
                _,idx = findmax(abs.(evl))
                DeltaVaryComplex = DeltaVaryComplex/evl[idx]
                Delta = zeros(eltype(DeltaVaryComplex),Mc,Mr)
                Delta[VaryComplexCols, VaryComplexRows] = DeltaVaryComplex
                Delta[FixedUnionRealCols, FixedUnionRealRows] = DeltaFixedUnionReal
                lb = 1/opnorm(Delta[VaryCols,VaryRows])
            end
        elseif nComplexVary > 0
            blk = index["simpleblk"]
            newloc = index["newloc"]
            sb = Dict(:azidx => index["repcomp"]["rows"], :bwidx => index["repcomp"]["cols"] ) 
            fb = Dict(:azidx => index["full"]["rows"], :bwidx => index["full"]["cols"] )  
            
            DeltaComplex = zeros(Mc,Mr)
            for i=1:size(blk,1)
                idx = newloc[i]
                if  blk[i,2] == 0 && blk[i,1] > 0
                    DeltaComplex[sb[:bwidx][idx],sb[:azidx][idx]] = eye(blk[i,1])
                elseif blk[i,2] > 0
                    # lvec[i] = ones(blk[i,1],1)
                    # rvec[i] = ones(1,blk[i,2])
                    Deltai = ones(blk[i,1],blk[i,2]) / opnorm(ones(blk[i,1],blk[i,2]))
                    DeltaComplex[[fb[:bwidx][idx]],[fb[:azidx][idx]]] =  Deltai
                end
            end
            Delta = zeros(Mc,Mr)
            Delta[VaryComplexCols, VaryComplexRows] = DeltaComplex[VaryComplexCols, VaryComplexRows]
            
            evl = eigvals(Delta*M)
            lb,idx = findmax(abs.(evl))
            Delta = Delta/evl[idx]
        end   
    elseif problemType in [:wcgain; :general]
        DeltaFix = Delta[FixedCols,FixedRows]
        eMDF = eigvals(M11*DeltaFix)
        if minimum(abs.(eMDF.-1)) < 1e-10
           lb = Inf
            Delta[VaryCols,VaryRows] .= zero(eltype(Delta))
        else
            F11 = length(FixedRows)
            Mloop = M22 + M21*DeltaFix/(eye(F11)-M11*DeltaFix)*M12
            if problemType == :wcgain
                U,S,V = svd(Mloop)
                lb = S[1,1]
                Delta[VaryCols,VaryRows] = (V[:,1]*U[:,1]')/lb
            else
                Vblk = index["simpleblk"]
                Vblk = Vblk[setdiff(1:end, index["FVidx"][:fixedBlkIdx]), :]
                VblkD,_ = _mkBlkData(Vblk)
                lb,Delta[VaryCols,VaryRows] = _mmupiter(Mloop,VblkD)
           end
        end
    end
    if lb <= 100*eps() || isnan(lb)
        # The fallback needs square dimensions for its zero perturbation, but
        # must not rewrite the block metadata reused by later frequency points.
        blk = copy(index["simpleblk"])
        idx = find(blk[:,1] .< 0 .|| blk[:,2] .== 0)
        blk[idx,:] = abs.(blk[idx,[1, 1]])
        Delta = zeros(Int,Tuple(sum(blk,dims=1)))
        lb = 0
    end
    return lb,Delta,bout,wout
    # Compute a valid lower bound and perturbation
end

function s4vecp(a::VecOrMat{<:Number},b::VecOrMat{<:Number},c::VecOrMat{<:Number},d::VecOrMat{<:Number})
    na = opnorm([a;;])
    nb = opnorm([b;;])
    nc = opnorm([c;;])
    nd = opnorm([d;;])
    if na<1 && (nb>0 || nc>0 || nd>0)
        betavec = [nd^2; 2*real(c'*d); nc^2+nb^2; 2*real(a'*b); na^2-1]
        r = roots(betavec)
        beta = abs.(r[imag(r) .>= 0])
        minres,imin = findmin(abs.(polyval(betavec,beta)))
        beta = beta[imin]
        alpha = beta^2
        n1vec = [a+beta*b; beta*(c+beta*d)]
        gamma = (minres .< 1e-3)
    else
        alpha = 0
        n1vec = [a; zeros(Int,size(d))]
        gamma = 0
    end
    return gamma,alpha,n1vec
end

function _sigmaub(blk::AbstractMatrix{<:Integer})
    nblk,_ = size(blk)
    trowd = zeros(Int,1,0)
    trowg = zeros(Int,1,0)
    blkcf = zeros(Int,2,0)
    blkcr = zeros(Int,2,0)
    blkr = zeros(Int,2,0)
    for i = 1:nblk
        if blk[i,1] < 0
            blkr = [blkr blk[i,:]]
        elseif blk[i,2] == 0
            blkcr = [blkcr blk[i,:]]
        else
            blkcf = [blkcf blk[i,:]]
        end
    end
    blkn = [blkr blkcr blkcf]'
    for i = 1:nblk
        if blkn[i,2] == 0 && blkn[i,1] > 0 # COMPLEX REPEATED SCALAR
            trowd = [trowd reshape(eye(blkn[i,1]),1,blkn[i,1]^2)]
        elseif blkn[i,2] == 0 && blkn[i,1] < 0 # REAL REPEATED SCALAR
            trowd = [trowd reshape(eye(abs(blkn[i,1])),1,blkn[i,1]^2)]
            trowg = [trowg zeros(Int,abs(blkn[i,1]))]
        elseif blkn[i,1] == -1 && blkn[i,2] == -1 # REAL 1x1
            trowd = [trowd 1]
            trowg = [trowg 0]
        else # COMPLEX FULL BLOCK
            trowd = [trowd 1]
        end
    end
    return trowd,trowg
end

function _mkcpert(b::AbstractVecOrMat{<:Number},a::AbstractVecOrMat{<:Number},index::Dict,opt::String)
    opt in ["dyad","unitary"] || error("_mkcpert.jl called incorrectly")
    dyad = opt == "unitary" ? false : true
    blk = index["simpleblk"]
    newloc = index["newloc"]
    
    sb = Dict("azidx" => index["repcomp"]["rows"],"bwidx" => index["repcomp"]["cols"], "loc" => index["repcomp"]["origloc"])
    fb = Dict("azidx" => index["full"]["rows"],"bwidx" => index["full"]["cols"], "loc" => index["full"]["origloc"])
    if length(a) != index["rdimm"] || length(b) != index["cdimm"]
        olda = a[:]
        a = zeros(eltype(a),index["rdimm"],1)
        a[index["allcomp"]["allrows"]] = olda
        
        oldb = b[:]
        b = zeros(eltype(b),index["cdimm"],1)
        b[index["allcomp"]["allcols"]] = oldb 
    end  
    
    Delta = zeros(eltype(b),length(b),length(a))
    nblk = size(blk,1)
    # lvec = []
    # rvec = []
    for i=1:nblk
        idx = newloc[i]
        if  blk[i,2] == 0 && blk[i,1] > 0
            sb_azidx = sb["azidx"][idx]
            sb_bwidx = sb["bwidx"][idx]
            ai = a[sb_azidx]
            bi = b[sb_bwidx]     
            maxmag,midx = findmax(abs.(ai))
            if maxmag < 100*eps()
                di = 0
            else
                di = bi[midx] / ai[midx]
            end
            if !dyad
                if abs.(di) < 100*eps()
                    di = 1
                else
                    di = di/abs(di)
                end
            end
            Delta[sb_bwidx, sb_azidx] = blk[i,1] == 1 ? di : di*eye(blk[i,1])
        elseif blk[i,2] > 0
            fb_azidx = fb["azidx"][idx]
            fb_bwidx = fb["bwidx"][idx]
            ai = a[fb_azidx]
            bi = b[fb_bwidx]
            nai = opnorm([ai;;])
            if nai < 100*eps()
                nai = 1
                ai = zeros(size(ai,1),size(ai,2))
            end
            # LV = bi/nai
            # RV = (ai')/nai
            # Deltai = LV*RV
            Deltai = bi/nai*(ai')/nai
            if dyad
                # push!(lvec,LV)
                # push!(rvec,RV)
            else      
                u,s,v = svd(Deltai)
                Deltai = u*I*v'
            end
            Delta[fb_bwidx, fb_azidx] = length(Deltai) == 1 ? Deltai[1] : Deltai
        end
    end
    # return Delta,lvec,rvec
    return Delta
end    

function _mufastub(M::AbstractMatrix{T},index::Dict,ub::Real,lb::Real) where {T<:Number}
    Mr,Mc = size(M)
    realr = index["allreal"]["allrows"]
    realc = index["allreal"]["allcols"]
    G_mask = index["masks"]["G_mask"]

    ubhigh = ub
    ublow = max(lb,1e-3)

    G = M[realr,realc].*G_mask
    G = real((G - G')/2im)
    gdiag,gu = schur(G)  
    gdiag = diag(gdiag)

    dMd = M
    dMd[realr,:] = gu'*dMd[realr,:]
    dMd[:,realc] = dMd[:,realc]*gu

    Lterm = ones(Mr,1)
    Rterm = ones(Mc,1)
    Cterm = copy(dMd)
    Cterm[realr,realc] = Cterm[realr,realc] - diagm(1im*gdiag)
    gdiag2 = gdiag.^2

    while (ubhigh-ublow) > 0.001*ublow  
        ubtry = (ublow+ubhigh)/2
        gtry2 = gdiag2/(ubtry.^2)
        Lterm[realr] = (1 .+ gtry2).^(-0.25)
        Rterm[realc] = Lterm[realr]
        if opnorm((Cterm/ubtry).*(Lterm*Rterm')) .< 1        
            ubhigh = ubtry
        else
            ublow = ubtry
        end
    end 

    if ubhigh < ub
        ub = ubhigh
        g = gdiag/ub
    else
        g = 0*gdiag
    end

    Lterm[realr] = (1 .+ g.^2).^(-0.25)
    Rterm[realc] = Lterm[realr]
    Cterm = dMd/ub
    Cterm[realr,realc] = Cterm[realr,realc] - diagm(1im*g)
    uu,ss,vv = svd(Cterm.*(Lterm*Rterm'))
    smax = maximum([maximum(ss);10*eps()])
    sidx = find((ss/smax) .> 0.95)
    isempty(sidx) && (sidx = 1)

    lidx = length(sidx)
    uu = uu[realr,sidx]
    ss = ss[sidx]
    vv = vv[realc,sidx]

    gtmp1 = repeat( g./(1 .+ g.^2)/2, 1, lidx)
    gtmp2 = repeat((1 .+ g.^2).^(-0.5), 1, lidx)
    ds_dg = -real(
        ((abs.(uu).^2 + abs.(vv).^2).*gtmp1).*transpose(ss) +
        1im*conj(uu).*vv.*gtmp2,
    )

    ds_dt_des = -10*(ss .- 0.9)
    gdir = pinv(ds_dg')*ds_dt_des
    ds_dt = ds_dg[:,1]'*gdir

    ds_dub = real( smax + 1im*uu[:,1]'*(gtmp2[:,1].*vv[:,1].*g) )/ub
    dub_dt = ds_dt/ds_dub
    dub = (lb - ub)/2
    t0 = dub ./ dub_dt
    t0 = isinf(t0[1]) ? 1e6 : min(maximum([t0;-1e6]), 1e6)

    # Take initial step & then backtrack; if necessary. 
    gt = g + t0*gdir[:]
    Lterm[realr] = (1 .+ gt.^2).^(-0.25)
    Rterm[realc] = Lterm[realr]
    Cterm = dMd/ub
    Cterm[realr,realc] = Cterm[realr,realc] - diagm(1im*gt)
    st = opnorm(Cterm.*(Lterm*Rterm'))
    cnt = 0
    while st > smax && cnt < 10
        t0 = t0/2
        gt = g+t0*gdir
        Lterm[realr] = (1 .+ gt.^2).^(-0.25)
        Rterm[realc] = Lterm[realr]
        Cterm = dMd/ub
        Cterm[realr,realc] = Cterm[realr,realc] - diagm(1im*gt)
        st = opnorm(Cterm.*(Lterm*Rterm'))
        cnt = cnt+1
    end

    # Update g if smax is reduced.
    (st < smax) && (g = gt)

    gbal = (1 .+ g.*g).^(-0.5)
    Dtmp = gu*diagm(gbal)*gu'
    
    Dr = eye(eltype(Dtmp),Mr,Mr)
    Dr[realr,realr] = Dtmp
    
    Dc = eye(eltype(Dtmp),Mc,Mc)
    Dc[realc,realc] = Dtmp
    
    Gcr = zeros(Mc,Mr)
    Gcr[realc,realr] = ub*(gu*diagm(g.*gbal)*gu')
    
    # Re-compute upper bound based on updated g-scale
    ubsq = maximum(real(eigvals(M'*Dr*M + 1im*(Gcr*M-M'*Gcr), Dc)))
    ub = sqrt(max(0,ubsq))

    return ub,Dr,Dc,Gcr
end

function _mudescentub(M::AbstractArray{T},index::Dict,ub::Real,Dr::AbstractMatrix{<:Number}=eye(size(M,1)),Dc::AbstractMatrix{<:Number}=eye(size(M,2)),Gcr::AbstractMatrix{<:Number}=zeros(size(M)[1:2])) where {T<:Number}
    Mr, Mc = size(M)[1:2]
    AD = size(M)[3:end]

    stoptol = 1+5e-4
    dtol = 1e-3
    descent_steps = 30   
    mincodel_steps = 30 

    nreal = index["allreal"]["num"]
    realrows = index["allreal"]["allrows"]
    realcols = index["allreal"]["allcols"]

    nrep = index["allrep"]["num"]
    reprows = index["allrep"]["allrows"]
    repcols = index["allrep"]["allcols"]

    nfull = index["full"]["num"]
    fullrows = index["full"]["allrows"]
    fullcols = index["full"]["allcols"]

    Drep_mask = index["masks"]["Drep_mask"]
    Dfull_maskr = index["masks"]["Dfull_maskr"]
    Dfull_maskc = index["masks"]["Dfull_maskc"]
    G_mask = index["masks"]["G_mask"]
    DfullIdxR = index["masks"]["Dfull_idxr"]

    VcIdx = index["FVidx"][:VcIdx]
    FcIdx = setdiff((1:Mc)',VcIdx)

    DrOld = copy(Dr)
    DcOld = copy(Dc)
    GcrOld = copy(Gcr)
    ubsqOld = float(ub)^2
    nstep = 0.0

    # Start Descent
    GcrM = zeros(T,Mc,Mc,AD...)
    NL = zeros(T,Mc,Mc,AD...)
    DcV = zeros(T,Mc,Mc)
    DcF = zeros(T,Mc,Mc)
    DcV[VcIdx,VcIdx] = Dc[VcIdx,VcIdx]
    DcF[FcIdx,FcIdx] = Dc[FcIdx,FcIdx]

    GcrM[realcols,:] = Gcr[realcols,realrows]*M[realrows,:]
    NL = M'*Dr*M + 1im*(GcrM-GcrM') - DcF

    for i1 = 1:descent_steps    
        # Find (clustered) max generalized eigenvals of:
        #    [M'*Dr*M+j*(Gcr*M-M'*Gcr')]*U = ub^2*Dc*U
        # ub is an upper bound and U is used to define Del
        ubsq = 0
        evals,Ui = eigen(NL,DcV)
        finiteIdx = .!isinf.(evals) .&& .!isnan.(evals)
        ubsq = max(ubsq, maximum(real(evals[finiteIdx])))

        eidx = find(real(evals[finiteIdx]) .>= 0.975*ubsq)
        if !isempty(eidx)
            NU = length(eidx)
            U = Ui[:,finiteIdx][:,eidx]
            V = M * U
        end

        evals2, U2 = eigen(Dr[reprows,reprows])
        evals2 = real(evals2)
        eidx2 = (evals2 .<= 2*dtol)
        U2p = U2[:, .!eidx2]
        U2 = U2[:, eidx2]
        tmpfull = diag(Dr[DfullIdxR,DfullIdxR])
        eidx3 = find( abs.(tmpfull .- dtol) .<= 0 )
        # nstep = 0
        if ubsq < 10*eps() 
            return sqrt(max(0,ubsq)), Dr, DcF, DcV, Gcr
        elseif (i1 == 1) || (nstep > 1e-4 && ubsq <= ubsqOld)
            DrOld = copy(Dr)
            DcOld = copy(Dc)
            GcrOld = copy(Gcr)
            ubsqOld = copy(ubsq)
        elseif ubsq < ubsqOld      
            return sqrt(ubsq), Dr, DcF, DcV, Gcr
        else
            DcV = zeros(T,Mc,Mc)
            DcF = zeros(T,Mc,Mc)
            DcV[VcIdx,VcIdx] = DcOld[VcIdx,VcIdx]
            DcF[FcIdx,FcIdx] = DcOld[FcIdx,FcIdx]
            return sqrt(ubsqOld), DrOld, DcF, DcV, GcrOld
            # return ub,Dr,DcF,DcV,Gcr
        end
        # Find min co(Del) which yields a descent direction.
        # 1st: Pick an initial update direction in co(Del):
        #         Dhat_0:=(Dhatrep,Dhatfull,Ghat)
        eta_dim = NU
        eta = ones(eta_dim, 1)
        Ve = sum(V,dims=2) / opnorm(eta)
        Ue = sum(U,dims=2) / opnorm(eta)
        ubUe = copy(Ue)
        ubUe[VcIdx] = sqrt(ubsq)*ubUe[VcIdx]

        Dhatrep = Ve[reprows]*Ve[reprows]' - ubUe[repcols]*ubUe[repcols]'
        Dhatrep = Dhatrep.*Drep_mask
    
        Dhatfull = Dfull_maskr*real(Ve[fullrows].*conj(Ve[fullrows]))
        Dhatfull = Dhatfull - Dfull_maskc*real(ubUe[fullcols].*conj(ubUe[fullcols]))
    
        VeUe = Ve[realrows]*Ue[realcols]'
        Ghat = 1im*(VeUe-VeUe')
        Ghat = Ghat.*G_mask
        # 2nd: Iterate towards min co(Del) using algorithm by [GIL]    
        for i2 = 1:( mincodel_steps*(eta_dim > 1))
            # Given Dhat_i compute:
            #   P_i = arg min_[P \in Del] <Dhat_i,P>
            # where P_i:=(Prep,Pfull,H)
            Drstep = zeros(eltype(Dhatrep),Mr,Mr)
            Drstep[reprows,reprows] = Dhatrep
            Drstep[fullrows,fullrows] = diagm(vec(Dhatfull'*Dfull_maskr))
            Dcstep = zeros(eltype(Dhatrep),Mc,Mc)
            Dcstep[repcols,repcols] = Dhatrep
            Dcstep[fullcols,fullcols] = diagm(vec(Dhatfull'*Dfull_maskc))

            mineval = Inf

            ubUi = copy(U)
            ubUi[VcIdx,:] = sqrt(ubsq)*ubUi[VcIdx,:]
            uGMu = U[realcols,:]'*Ghat*V[realrows,:]
            evals,eta = eigen(V'*Drstep*V + 1im*(uGMu - uGMu') - (ubUi'*Dcstep*ubUi))
            evals = real(evals)
            minidx = argmin(evals)
            if evals[minidx] < mineval
                mineval = evals[minidx]
                mineta = eta[:,minidx]
                minUidx = 1
            end
            eta = mineta/opnorm([mineta;;])
            Ve = V*eta
            Ue = U*eta
            ubUe = copy(Ue)
            ubUe[VcIdx] = sqrt(ubsq)*ubUe[VcIdx]
            Prep = Ve[reprows]*Ve[reprows]' - ubUe[repcols]*ubUe[repcols]'
            Prep = Prep.*Drep_mask    # zero out off-diagonal blocks
    
            Pfull = Dfull_maskr*real(Ve[fullrows].*conj(Ve[fullrows]))
            Pfull = Pfull - Dfull_maskc*real(ubUe[fullcols].*conj(ubUe[fullcols]))

            VeUe = Ve[realrows]*Ue[realcols]'
            H = 1im*(VeUe-VeUe')
            H = H.*G_mask  # zero out off-diagonal blocks  
    
            # Take a step:
            #   Dhat_(i+1} = min co{Dhat_i,P_i)
            #              = Dhat_i + t*(P_i-Dhat_i)
            # where t = -<Dhat_i;P_i-Dhat_i> / <P_i-Dhat_i;P_i-Dhat_i>
            Deltarep = Prep - Dhatrep
            Deltafull = Pfull - Dhatfull
            DeltaG = H - Ghat
            n = 0
            d = 0
            if nrep > 0         
                n = n + sum(Dhatrep.*(transpose(Deltarep)))
                d = d + sum(Deltarep.*(transpose(Deltarep)))
            end
            if nreal > 0
                n = n + sum(Ghat.*(DeltaG'))
                d = d + sum(DeltaG.*(DeltaG'))
            end
            if nfull > 0            
                n = n + Dhatfull'*Deltafull
                d = d + Deltafull'*Deltafull
            end
            
            if real(d) <= 1e-6
                t = Int(real(n) < 0)
            else
                t = min(maximum([-real(n/d), 0]), 1)
            end                    
            Dhatrep = Dhatrep + t*Deltarep
            Dhatfull = Dhatfull + t*Deltafull
            Ghat = Ghat + t*DeltaG       
        end # for loop for [GIL]'s algorithm 
        
        if !isempty(U2)
            ee,QQ = eigen(U2'*Dhatrep*U2)
            ee = real(ee)
            ee[ee .> 0] .= 0
            Dhatrep = U2p*(U2p'*Dhatrep*U2p)*U2p' + U2*( QQ*ee*QQ') *U2'
        end
        if !isempty(eidx3)
            Dhatfull[eidx3] = min.(Dhatfull[eidx3],0)
        end
        
        # 3rd: Convert into full D/G matrices.  This is a descent direction.
        Drstep = zeros(eltype(Dhatrep),Mr,Mr)
        Drstep[reprows,reprows] = Dhatrep
        Drstep[fullrows,fullrows] = diagm((Dhatfull'*Dfull_maskr)[:])
        Dcstep = zeros(eltype(Dhatrep),Mc,Mc)
        Dcstep[repcols,repcols] = Dhatrep
        Dcstep[fullcols,fullcols] = diagm((Dhatfull'*Dfull_maskc)[:])
        Gcrstep = zeros(eltype(Ghat),Mc,Mr)
        Gcrstep[realcols,realrows] = Ghat

        # 4th: Take a step in the descent direction
        GcrstepM = zeros(T,Mc,Mc)
        DcVstep = zeros(T,Mc,Mc)
        DcFstep = zeros(T,Mc,Mc)
        DcVstep[VcIdx,VcIdx] = Dcstep[VcIdx,VcIdx]
        DcFstep[FcIdx,FcIdx] = Dcstep[FcIdx,FcIdx]

        GcrstepM[realcols,:] = Gcrstep[realcols,realrows] * M[realrows,:]            
        NLstep = M'*Drstep*M + 1im*(GcrstepM-GcrstepM') - DcFstep
        ALLeig = real(eigvals(NL-ubsq*DcV, NLstep-ubsq*DcVstep))
        if any(isnan.(ALLeig))
            t = 0
        else
            ALLeig = sort(ALLeig)
            mineig = minimum(abs.(ALLeig))
            idx = find(abs.(ALLeig) .== mineig)
            t = idx[end]+1 <= length(ALLeig) ? ALLeig[idx[end]+1]/2 : Inf
        end

        if rcond(Dcstep) < eps() || rcond(Dc-dtol*eye(Mc)) < eps()
            tmpeig = real(eigvals(Dcstep, Dc-dtol*eye(Mc)))
        else
            tmpeig = real(eigvals((Dc-dtol*eye(Mc))\Dcstep))
        end
        tmax = any(isnan.(tmpeig)) ? 0 : 1/maximum([tmpeig; 1e-9])
        nstep = opnorm([Dcstep[:]; Gcrstep[:];;])

        # Take step 
        t = min(t, tmax)
        NL = NL-t*NLstep
        Gcr = Gcr-t*Gcrstep
        Dr = Dr-t*Drstep
        Dc = Dc-t*Dcstep

        dmax = 1
        NL = NL/dmax
        Gcr = Gcr/dmax
        Dr = Dr/dmax
        Dc = Dc/dmax
        DcV, DcF = zeros(eltype(Dc),Mc,Mc), zeros(eltype(Dc),Mc,Mc)
        DcV[VcIdx,VcIdx] = Dc[VcIdx,VcIdx]
        DcF[FcIdx,FcIdx] = Dc[FcIdx,FcIdx]

        if rcond(Dc) < sqrt(eps())
            Dr = copy(DrOld)
            Gcr = copy(GcrOld)
            DcV = zeros(T, Mc,Mc)
            DcF = zeros(T, Mc,Mc)
            DcV[VcIdx,VcIdx] = DcOld[VcIdx,VcIdx]
            DcF[FcIdx,FcIdx] = DcOld[FcIdx,FcIdx]
            ub = sqrt(ubsqOld)
            return ub, Dr, DcF, DcV, Gcr
        end
    end
    ubsq = maximum(real(eigvals(NL,DcV)))

    if ubsq < ubsqOld
        ub = sqrt(ubsq)
    else    
        Dr = DrOld
        DcV = zeros(T,Mc,Mc)
        DcF = zeros(T,Mc,Mc)
        DcV[VcIdx,VcIdx] = DcOld[VcIdx,VcIdx]
        DcF[FcIdx,FcIdx] = DcOld[FcIdx,FcIdx]
        Gcr = GcrOld
        ub = sqrt(ubsqOld)
    end
    return ub, Dr, DcF, DcV, Gcr
end

function _mkBlkData(blk::AbstractMatrix{<:Integer},fixBlkIdx::VecOrMat{<:Integer}=zeros(Int,0,1))
    nblk = size(blk,1)
    for ii = 1:nblk
        if blk[ii,:] == [1,0]
           blk[ii,:]  = [1,1] 
        elseif blk[ii,:] == [-1,1] 
            blk[ii,:]  = [-1,0]
        elseif blk[ii,:] == [-1,-1]
            blk[ii,:] = [-1,0]
        end
    end
    blk2 = copy(blk)
    nblk = size(blk2,1)
    blk3 = zeros(Int,nblk,3)
    for i1 = 1:nblk
        if blk[i1,2] == 0 
            blk3[i1,:] = [1, 1, blk2[i1,1]]
        elseif blk2[i1,2] > 0 
            blk3[i1,:] = [blk2[i1,1], blk2[i1,2], 1]
        else
            error(@tr("blk is invalid. First column of blk must be non-negative integers"))
        end
    end
    index = blk2idx(blk3)
    index["allreal"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => zeros(Int,0), "repeated" => zeros(Int,0))
    for i = 1:index["sreal"]["num"]
        index["allreal"]["num"] += 1
        # index["allreal"]["rows"][index["allreal"]["num"]] = index["sreal"]["rows"][i]
        # index["allreal"]["cols"][index["allreal"]["num"]] = index["sreal"]["cols"][i]
        push!(index["allreal"]["rows"],index["sreal"]["rows"][i])
        push!(index["allreal"]["cols"],index["sreal"]["cols"][i])
        index["allreal"]["origloc"] = [index["allreal"]["origloc"]; index["sreal"]["origloc"][i]]
        index["allreal"]["repeated"] = [index["allreal"]["repeated"]; 1]
    end
    for i = 1:index["repreal"]["num"]
        index["allreal"]["num"] += 1
        # index["allreal"]["rows"][index["allreal"]["num"]] = index["repreal"]["rows"][i]
        # index["allreal"]["cols"][index["allreal"]["num"]] = index["repreal"]["cols"][i]
        push!(index["allreal"]["rows"],index["repreal"]["rows"][i])
        push!(index["allreal"]["cols"],index["repreal"]["cols"][i])
        index["allreal"]["origloc"] = [index["allreal"]["origloc"]; index["repreal"]["origloc"][i]]
        index["allreal"]["repeated"] = [index["allreal"]["repeated"]; index["repreal"]["repeated"][i]]
    end
    index["allreal"]["realblk"] = blk2[index["allreal"]["origloc"],:]

    index["allcomp"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => zeros(Int,0), "repeated" => zeros(Int,0))
    for i = 1:index["repcomp"]["num"]
        index["allcomp"]["num"] += 1
        # index["allcomp"]["rows"][index["allcomp"]["num"]] = index["repcomp"]["rows"][i]
        # index["allcomp"]["cols"][index["allcomp"]["num"]] = index["repcomp"]["cols"][i]
        push!(index["allcomp"]["rows"],index["repcomp"]["rows"][i])
        push!(index["allcomp"]["cols"],index["repcomp"]["cols"][i])
        index["allcomp"]["origloc"] = [index["allcomp"]["origloc"]; index["repcomp"]["origloc"][i]]
        index["allcomp"]["repeated"] = [index["allcomp"]["repeated"]; index["repcomp"]["repeated"][1]]
    end
    for i = 1:index["full"]["num"]
        index["allcomp"]["num"] += 1
        # index["allcomp"]["rows"][index["allcomp"]["num"]] = index["full"]["rows"][i]
        # index["allcomp"]["cols"][index["allcomp"]["num"]] = index["full"]["cols"][i]
        push!(index["allcomp"]["rows"],index["full"]["rows"][i])
        push!(index["allcomp"]["cols"],index["full"]["cols"][i])
        index["allcomp"]["origloc"] = [index["allcomp"]["origloc"]; index["full"]["origloc"][i]]
        index["allcomp"]["repeated"] = [index["allcomp"]["repeated"]; 1]
    end
    index["allcomp"]["compblk"] = blk2[index["allcomp"]["origloc"],:]

    index["allrep"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => zeros(Int,0), "repeated" => zeros(Int,0))
    for i = 1:index["repreal"]["num"]
        index["allrep"]["num"] += 1
        # index["allrep"]["rows"][index["allrep"]["num"]] = index["repreal"]["rows"][i]
        # index["allrep"]["cols"][index["allrep"]["num"]] = index["repreal"]["cols"][i]
        push!(index["allrep"]["rows"],index["repreal"]["rows"][i])
        push!(index["allrep"]["cols"],index["repreal"]["cols"][i])
        index["allrep"]["origloc"] = [index["allrep"]["origloc"]; index["repreal"]["origloc"][i]]
        index["allrep"]["repeated"] = [index["allrep"]["repeated"]; index["repreal"]["repeated"][i]]
    end
    for i = 1:index["sreal"]["num"]
        index["allrep"]["num"] += 1
        # index["allrep"]["rows"][index["allrep"]["num"]] = index["sreal"]["rows"][i]
        # index["allrep"]["cols"][index["allrep"]["num"]] = index["sreal"]["cols"][i]
        push!(index["allrep"]["rows"],index["sreal"]["rows"][i])
        push!(index["allrep"]["cols"],index["sreal"]["cols"][i])
        index["allrep"]["origloc"] = [index["allrep"]["origloc"]; index["sreal"]["origloc"][i]]
        index["allrep"]["repeated"] = [index["allrep"]["repeated"]; 1]
    end
    for i = 1:index["repcomp"]["num"]
        index["allrep"]["num"] += 1
        # index["allrep"]["rows"][index["allrep"]["num"]] = index["repcomp"]["rows"][i]
        # index["allrep"]["cols"][index["allrep"]["num"]] = index["repcomp"]["cols"][i]
        push!(index["allrep"]["rows"],index["repcomp"]["rows"][i])
        push!(index["allrep"]["cols"],index["repcomp"]["cols"][i])
        index["allrep"]["origloc"] = [index["allrep"]["origloc"]; index["repcomp"]["origloc"][i]]
        index["allrep"]["repeated"] = [index["allrep"]["repeated"]; index["repcomp"]["repeated"][i]]
    end

    # Return new locations  of the blocks
    nr = index["allreal"]["num"]
    nf = index["full"]["num"]
    nrc = index["repcomp"]["num"]
    newloc = zeros(Int,nblk,1)
    newloc[index["allreal"]["origloc"]] = 1:nr
    newloc[index["full"]["origloc"]] = 1:nf
    newloc[index["repcomp"]["origloc"]] = 1:nrc
    index["newloc"] = newloc

    # Store all rows/cols for full, real, and repeated scalar blocks
    index["full"]["allrows"] = _allvcat(index["full"]["rows"])
    index["full"]["allcols"] = _allvcat(index["full"]["cols"])
    index["allreal"]["allrows"] = _allvcat(index["allreal"]["rows"])
    index["allreal"]["allcols"] = _allvcat(index["allreal"]["cols"])
    index["allcomp"]["allrows"] = _allvcat(index["allcomp"]["rows"])
    index["allcomp"]["allcols"] = _allvcat(index["allcomp"]["cols"])
    index["allrep"]["allrows"] = _allvcat(index["allrep"]["rows"])
    index["allrep"]["allcols"] = _allvcat(index["allrep"]["cols"])
    index["repcomp"]["allrows"] = _allvcat(index["repcomp"]["rows"])
    index["repcomp"]["allcols"] = _allvcat(index["repcomp"]["cols"])
    # Form masks used to vectorize code
    Mr = index["rdimm"]
    Mc = index["cdimm"]
    Drep_mask = zeros(Int,Mr,Mr)
    for i1 = 1:index["allrep"]["num"]
        tmprep = index["allrep"]["repeated"][i1]
        tmpidx = index["allrep"]["rows"][i1]
        Drep_mask[tmpidx,tmpidx] = (length(tmpidx) == 1) ? 1 : ones(tmprep,tmprep)
    end
    Drep_mask = Drep_mask[index["allrep"]["allrows"], index["allrep"]["allrows"]]
    # index["masks"]["Drep_mask"] = Drep_mask

    Dfull_maskr = zeros(Int,index["full"]["num"],Mr)
    Dfull_maskc = zeros(Int,index["full"]["num"],Mc)
    Dfull_idxr = zeros(Int,index["full"]["num"])
    for i1 = 1 : index["full"]["num"]
        Dfull_idxr[i1] = index["full"]["rows"][i1][1]
        Dfull_maskr[i1,index["full"]["rows"][i1]] = isscalar(index["full"]["rows"][i1]) ? 1 : ones(index["full"]["rows"][i1])
        Dfull_maskc[i1,index["full"]["cols"][i1]] = isscalar(index["full"]["cols"][i1]) ? 1 : ones(index["full"]["cols"][i1])
        # fill!(Dfull_maskr[i1:i1,index["full"]["rows"][i1]],1)
        # fill!(Dfull_maskr[i1:i1,index["full"]["cols"][i1]],1)
    end
    Dfull_maskr = Dfull_maskr[:,index["full"]["allrows"]]
    Dfull_maskc = Dfull_maskc[:,index["full"]["allcols"]]

    index["masks"] = Dict("Drep_mask" => Drep_mask,"Dfull_maskr" => Dfull_maskr,"Dfull_maskc" => Dfull_maskc,"Dfull_idxr" => Dfull_idxr)

    # real_mask used in mmupiter
    real_mask = zeros(index["allreal"]["num"],Mr)
    for i1 = 1:index["allreal"]["num"]
        tmprep = index["allreal"]["repeated"][i1]
        tmpidx = index["allreal"]["rows"][i1]
        real_mask[i1,tmpidx] = (length(tmpidx) == 1) ? 1 : ones(1,tmprep)
    end
    real_mask = real_mask[:,index["allreal"]["allrows"]]
    index["masks"]["real_mask"] =  real_mask
    index["masks"]["G_mask"] =  real_mask'*real_mask
    # repc_mask used in mmupiter
    repc_mask = zeros(index["repcomp"]["num"],Mr)
    for i1 = 1:index["repcomp"]["num"]
        tmprep = index["repcomp"]["repeated"][i1]
        tmpidx = index["repcomp"]["rows"][i1]
        repc_mask[i1,tmpidx] = ones(1,tmprep)
    end
    repc_mask = repc_mask[:,index["repcomp"]["allrows"]]
    index["masks"]["repc_mask"] =  repc_mask

    # Mask for full blocks of Delta
    index["masks"]["DeltaFull_mask"] =  Dfull_maskc'*Dfull_maskr

    # Mask used in osborne's method
    nd = length(index["allrep"]["allrows"]) + index["full"]["num"]
    ridxm = index["ridxm"]
    cidxm = index["cidxm"]
    sr = zeros(Int,nd,Mr)
    sc = zeros(Int,Mc,nd)
    sidx = 1
    cnt = 1
    afullidx = Int[]
    for i1=1:size(blk,1)
        cdim = abs(blk[i1,1])
        rdim = blk[i1,2]
        idxr = ridxm[i1] : (ridxm[i1+1]-1)
        idxc = cidxm[i1] : (cidxm[i1+1]-1)
        if rdim == 0 && cdim > 1
            idx = sidx:(sidx+cdim-1)
            sr[idx,idxr] = eye(cdim)
            sc[idxc,idx] = eye(cdim)
            sidx = sidx+cdim
        else
            if rdim == 0
                rdim = 1
            else
                push!(afullidx,sidx)
                # afullidx = sidx
                # cnt = cnt+1
            end
            sr[sidx,idxr] = ones(Int,1,rdim)
            sc[idxc,sidx] = ones(Int,cdim,1)
            sidx = sidx+1
        end  
    end
    afullidx = [afullidx';;]
    index["masks"]["sr"] = sr
    index["masks"]["sc"] = sc
    if index["full"]["num"] > 0
        index["masks"]["afullidx"] = afullidx
    else
        index["masks"]["afullidx"] = zeros(1,0)
    end
    index["FVidx"] = _FixedVaryIndex(index, fixBlkIdx)
    # Determine Problem Type
    fixedBlkIdx = index["FVidx"][:fixedBlkIdx]
    varyBlkIdx = (1:nblk)[setdiff(1:end,fixedBlkIdx)]
    allVary = isempty(fixedBlkIdx)
    if allVary
        problemType = :robstab
    elseif length(varyBlkIdx) == 1 && (blk[varyBlkIdx[1],2] > 0 || blk[varyBlkIdx[1],1] == 1)
        problemType = :wcgain
    elseif length(fixedBlkIdx) == 1 && (blk[fixedBlkIdx[1],2] > 0 || blk[fixedBlkIdx[1],1] == 1)
        problemType = :robgain
    else
        problemType = :general
    end
    index["problemType"] = problemType
    return index,blk
end

function _FixedVaryIndex(index::Dict, fixedBlkIdx::VecOrMat{<:Integer})
    nblk = size(index["simpleblk"],1)
    nR = index["rdimm"]
    nC = index["cdimm"]
    fixedBlkIdx = reshape(fixedBlkIdx,1, length(fixedBlkIdx))
    varyBlkIdx = collect(1:nblk)
    deleteat!(varyBlkIdx,fixedBlkIdx)

    RealRows = sort(index["allreal"]["allrows"])
    RealCols = sort(index["allreal"]["allcols"])
    ComplexRows = sort(index["allcomp"]["allrows"])
    ComplexCols = sort(index["allcomp"]["allcols"])
    VaryRows = zeros(Int,0)
    VaryCols = zeros(Int,0)
    for i=1:length(varyBlkIdx)
        # Referenced to Rows/Cols of M
        VaryRows = [VaryRows; index["ridxm"][varyBlkIdx[i]] : index["ridxm"][varyBlkIdx[i]+1]-1]
        VaryCols = [VaryCols; index["cidxm"][varyBlkIdx[i]] : index["cidxm"][varyBlkIdx[i]+1]-1]
    end
    FixedRows = collect(1:nR)
    deleteat!(FixedRows,VaryRows)
    FixedCols = collect(1:nC)
    deleteat!(FixedCols,VaryCols)
    if isempty(index["simpleblk"])
        VaryCIdx = zeros(Int,0)
        FixedCIdx = zeros(Int,0)
    else
        Cidx = find(index["simpleblk"][:,1] .> 0)
        VaryCIdx = varyBlkIdx[find(ismember(varyBlkIdx,Cidx))]
        FixedCIdx = fixedBlkIdx[find(ismember(fixedBlkIdx,Cidx))]
    end
     
    FixedUnionRealCols = unique([FixedCols;RealCols])
    FixedUnionRealRows = unique([FixedRows;RealRows])
    VaryComplexCols = VaryCols[find(ismember(VaryCols,ComplexCols))]
    VaryComplexRows = VaryRows[find(ismember(VaryRows,ComplexRows))]
     
    cidxm = index["cidxm"]
    VcIdx = zeros(Int,0)
    for i1=1:nblk
        if !any(i1 .== fixedBlkIdx)
            VcIdx = [VcIdx; cidxm[i1]:cidxm[i1+1]-1]
        end
    end
    return Dict(:VaryRows => VaryRows, :VaryCols => VaryCols, :fixedBlkIdx => fixedBlkIdx,:FixedRows => FixedRows,:FixedCols => FixedCols,
            :VaryCIdx => VaryCIdx, :FixedCIdx => FixedCIdx, :FixedUnionRealCols => FixedUnionRealCols, :FixedUnionRealRows => FixedUnionRealRows,
            :VaryComplexCols => VaryComplexCols, :VaryComplexRows => VaryComplexRows, :VcIdx => VcIdx)
end


function _allvcat(v::Vector)
    V = Int[]
    for i = 1 : length(v)
        V = vcat(V,v[i])
    end
    return V
end

function blk2idx(blk::AbstractMatrix{<:Integer})
    if size(blk,2) != 3
        error("Incorrect column dimension of block structure")
    end
    
    colloc = 1
    rowloc = 1
    nblk = size(blk,1)
    rpertdim = blk[:,1].*abs.(blk[:,3])     # rows of DELTA, cols of M
    cpertdim = blk[:,2].*abs.(blk[:,3])     # cols of DELTA, rows of M

    index = Dict("rdimm" => sum(cpertdim),"cdimm" => sum(rpertdim), "cidxm" => cumsum([1;rpertdim]), "ridxm" => cumsum([1;cpertdim]),"simpleblk" => zeros(Int,0,2))
    # ALL ROWS/COLS refer to M 
    index["repcomp"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => Int[], "repeated" => zeros(Int,0,1))
    index["repreal"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => Int[], "repeated" => zeros(Int,0,1))
    index["full"] = Dict("num" => 0, "rows" => [], "cols" => [], "dim" => zeros(Int,0,2), "origloc" => zeros(Int,0,1))
    index["sreal"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => Int[])
    index["repcomp"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => Int[], "repeated" => zeros(Int,0,1))
    index["repreal"] = Dict("num" => 0, "rows" => [], "cols" => [], "origloc" => Int[], "repeated" => zeros(Int,0,1))
    for i = 1:nblk
        if blk[i,1]*blk[i,2] .== 1   # scalar
            if blk[i,3] .> 1         # complex , repeated
                index["repcomp"]["num"] += 1
                # index["repcomp"]["rows"][index["repcomp"]["num"]] = rowloc:rowloc+blk[i,3]-1
                # index["repcomp"]["cols"][index["repcomp"]["num"]] = colloc:colloc+blk[i,3]-1
                push!(index["repcomp"]["rows"],rowloc:rowloc+blk[i,3]-1)
                push!(index["repcomp"]["cols"],colloc:colloc+blk[i,3]-1)
                index["repcomp"]["origloc"] = [index["repcomp"]["origloc"]; i]
                index["repcomp"]["repeated"] = [index["repcomp"]["repeated"]; blk[i,3]]
                rowloc = rowloc + blk[i,3]
                colloc = colloc + blk[i,3]
                index["simpleblk"] = [index["simpleblk"]; blk[i,3] 0]
            elseif blk[i,3] .== 1         # complex, scalar, not repeated, shows up as full()
                index["full"]["num"] += 1
                push!(index["full"]["rows"],rowloc)
                push!(index["full"]["cols"],colloc)
                # index["full"]["rows"][index["full"]["num"]] = rowloc
                # index["full"]["cols"][index["full"]["num"]] = colloc
                index["full"]["origloc"] = [index["full"]["origloc"]; i]
                index["full"]["dim"] = [index["full"]["dim"];1 1]
                rowloc = rowloc + blk[i,3]
                colloc = colloc + blk[i,3]
                index["simpleblk"] = [index["simpleblk"]; 1 1]
            elseif blk[i,3] .== -1         # real, scalar
                index["sreal"]["num"] += 1
                push!(index["sreal"]["rows"],rowloc)
                push!(index["sreal"]["cols"],colloc)
                # index["sreal"]["rows"][index["sreal"]["num"]] = rowloc
                # index["sreal"]["cols"][index["sreal"]["num"]] = colloc
                index["sreal"]["origloc"] = [index["sreal"]["origloc"]; i]
                rowloc = rowloc + abs(blk[i,3])
                colloc = colloc + abs(blk[i,3])
                index["simpleblk"] = [index["simpleblk"]; -1 0]

             elseif blk[i,3] .< -1         # real, repeated
                index["repreal"]["num"] += 1
                # index["repreal"]["rows"][index["repreal"]["num"]] = rowloc:rowloc+abs(blk[i,3])-1
                # index["repreal"]["cols"][index["repreal"]["num"]] = colloc:colloc+abs(blk[i,3])-1
                push!(index["repreal"]["rows"],rowloc:rowloc+abs(blk[i,3])-1)
                push!(index["repreal"]["cols"],colloc:colloc+abs(blk[i,3])-1)
                index["repreal"]["origloc"] = [index["repreal"]["origloc"]; i]
                index["repreal"]["repeated"] = [index["repreal"]["repeated"]; abs(blk[i,3])]
                rowloc = rowloc + abs(blk[i,3])
                colloc = colloc + abs(blk[i,3])
                index["simpleblk"] = [index["simpleblk"]; blk[i,3] 0]
             elseif blk[i,3] .== 0
                error(@tr("Scalar block repeated zero times..."))
             end
          else                          # full block
            if blk[i,3] .> 1             # complex , repeated
                index["repfull"]["num"] += 1
                # index["repfull"]["rows"][index["repfull"]["num"]] = rowloc:rowloc+(blk[i,2]*blk[i,3])-1
                # index["repfull"]["cols"][index["repfull"]["num"]] = colloc:colloc+(blk[i,1]*blk[i,3])-1
                push!(index["repfull"]["rows"],rowloc:rowloc+(blk[i,2]*blk[i,3])-1)
                push!(index["repfull"]["cols"],colloc:colloc+(blk[i,1]*blk[i,3])-1)
                index["repfull"]["origloc"] = [index["repfull"]["origloc"]; i]
                index["repfull"]["repeated"] = [index["repfull"]["repeated"]; blk[i,3]]
                index["repfull"]["dim"] = [index["repfull"]["dim"]; blk[i,[1 2]]]
                rowloc = rowloc + (blk[i,2]*blk[i,3])
                colloc = colloc + (blk[i,1]*blk[i,3])
                index["simpleblk"] = [index["simpleblk"]; ones(blk[i,3],1)*blk[i,[1 2]]]
            elseif blk[i,3] .== 1         # complex full (once)
                index["full"]["num"] += 1
                # index["full"]["rows"][index["full"]["num"]] = rowloc:rowloc+blk[i,2]-1
                # index["full"]["cols"][index["full"]["num"]] = colloc:colloc+blk[i,1]-1
                push!(index["full"]["rows"],rowloc:rowloc+blk[i,2]-1)
                push!(index["full"]["cols"],colloc:colloc+blk[i,1]-1)
                index["full"]["origloc"] = [index["full"]["origloc"]; i]
                index["full"]["dim"] = [index["full"]["dim"]; blk[i,[1 2]]]
                rowloc = rowloc + (blk[i,2]*blk[i,3])
                colloc = colloc + (blk[i,1]*blk[i,3])
                index["simpleblk"] = [index["simpleblk"]; blk[i,[1 2]]]
            elseif blk[i,3] .< 0         # real, full()
                error(@tr("Real full block currently not allowed ..."))
            elseif blk[i,3] .== 0
                error(@tr("Scalar block repeated zero times..."))
            end
        end
    end

    return index
end

function _ami2ynrow(Dcell::Vector,Gcell::Vector,blk::AbstractMatrix{<:Integer},beta::Real,dflag::Bool=false)
    nblk = size(blk,1)
    cds = zeros(Int,1,0)
    rds = zeros(Int,1,0)
    scalds = zeros(Int,1,0)
    gs = zeros(Int,1,0)

    for i = 1:nblk
        if blk[i,1] < -1 && blk[i,2] == 0
            bd = -blk[i,1]
            if dflag
                df = Dcell[i]
            else
                da = Dcell[i]
                df = sqrt(da)
            end
            ga = Gcell[i]
            if all(ga[:].==0)
               gf = ga
            else
               gf = (1/beta)*(df\ga/df)
            end
            evl,evc = eigen(gf)
            gpd = real(evl)
            dp = diagm(sqrt.(sqrt.(ones(bd)+gpd.*gpd)))*evc'*df
            gs = [gs transpose(gpd)]
            rds = [rds transpose(reshape(dp,bd*bd,1))]
        elseif blk[i,1] > 1 && blk[i,2] == 0
            bd = blk[i,1]
            if dflag
                df = Dcell[i]
            else
                da = Dcell[i]
                df = sqrt(da)
            end
            dp = df
            cds = [cds transpose(reshape(dp,bd*bd,1))]
        elseif blk[i,1] > 0 && blk[i,2] > 0
            if dflag
                df = Dcell[i]
            else
                da = Dcell[i]
                df = sqrt.(real(da))
            end
            dp = df
            scalds = [scalds dp]
        elseif  blk[i,1] == 1 && blk[i,2] == 0
            if dflag
                df = Dcell[i]
            else
                da = Dcell[i]
                df = sqrt.(real(da))
            end
            dp = df
            scalds = [scalds dp]
        elseif  blk[i,1] == -1
            if dflag
                df = Dcell[i]
                da = df*df
            else
                da = Dcell[i]
                df = sqrt.(real(da))
            end
            ga = real(Gcell[i])
            gf = (1/beta)*(ga/da)
            gp = real(gf)
            dp = sqrt.(sqrt.(1 .+ gp*gp))*df
            gs = [gs gp]
            rds = [rds dp]
        end
    end
    return [rds cds scalds], gs
end

function _goptvl(opt,tag,defval,nfval)
    tagchar = tag isa Char ? tag : first(tag)
    loc = findfirst(==(tagchar),opt)
    loc === nothing && return nfval
    loc == lastindex(opt) && return defval

    suffix = SubString(opt,nextind(opt,loc))
    digits = match(r"^\d+",suffix)
    return digits === nothing ? defval : parse(Int,digits.match)
end

function _DGinit(M::AbstractArray{T},index::Dict,Opt::String="") where {T<:Number}
    blk = index["simpleblk"]
    FV = index["FVidx"]
    blkFIdx = FV[:fixedBlkIdx][:] # 原 FV[:fixedBlkIdx] 为单行矩阵

    nAD = size(M,3)
    Mavg = sum(M,dims=3)/nAD
    if isempty(blkFIdx)
        ub = opnorm(Mavg)
        Dr = eye(size(M,1))
        Dc = eye(size(M,2))
        Gcr = zeros(size(M,2),size(M,1))
        Grc = Gcr'
        ub = 1.01*ub
        if index["allreal"]["num"] > 0 && ub > 10*eps()
            ubFast,DrFast,DcFast,GcrFast = _mufastub(Mavg,index,ub,0)
            if ubFast < ub
                Dr = DrFast
                Dc = DcFast
                Gcr = GcrFast
                Grc = GcrFast'
                ub = 1.01*ubFast
            end
            (nAD <= 1) || (ub *= 5)
        else
            nrm = zeros(nAD)
            for i=1:nAD
                nrm[i] = opnorm(M[:,:,i])
            end
            ub = 1.01*maximum(nrm)
        end
    else
        blkF = blk[blkFIdx,:]
        blkV = blk[setdiff(1:end,blkFIdx), :]
        
        tmpF = abs.(blkF)
        sbF = (tmpF[:,2] .== 0)
        tmpF[sbF,2] = tmpF[sbF,1]
        blkFasFull = sum(tmpF,dims=1)
        blkR = [blkV; blkFasFull]
        blkRdata,_ = _mkBlkData(blkR)
        MF = Mavg[FV[:FixedRows], FV[:FixedCols]]
        if length(blkFIdx) == 1 && blk[blkFIdx[1],2] > 0
            bndsF = opnorm(MF)
            dcF = eye(size(MF,2))
            drF = eye(size(MF,1))
            GcrF = zeros(size(MF,2),size(MF,1))
            GrcF = GcrF'
            DLeft = drF
            DRight = dcF
        else
            bndsF,mui = mussv(MF,blkF,join([Opt,"U"]))
            _,VSigma,VLmi = mussvextract(mui;nargout=3)
            dcF = VLmi["Dc"]
            drF = VLmi["Dr"]
            GcrF = VLmi["Gcr"]
            GrcF = VLmi["Grc"]
            DLeft = VSigma["DLeft"]
            DRight = VSigma["DRight"]
        end
        if bndsF[1]<1
            Mo = Mavg
            Mo[FV[:FixedRows],:] = DLeft*Mo[FV[:FixedRows],:]
            Mo[:, FV[:FixedCols]] = Mo[:,FV[:FixedCols]]/DRight
            MoS = Mo[ [FV[:VaryRows]; FV[:FixedRows]], [FV[:VaryCols]; FV[:FixedCols]] ]
            MS = Mavg[ [FV[:VaryRows]; FV[:FixedRows]], [FV[:VaryCols]; FV[:FixedCols]] ]
            _,drV,dciV = _osbal(MoS,blkRdata,"d")
            drV = drV[1:end-blkFasFull[2],1:end-blkFasFull[2]]/drV[end,end]
            drV = drV'*drV
            dcV = inv(dciV[1:end-blkFasFull[1],1:end-blkFasFull[1]]/dciV[end,end])
            dcV = dcV'*dcV
            M12 = Mavg[FV[:VaryRows], FV[:FixedCols]]
            M22 = Mavg[FV[:FixedRows], FV[:FixedCols]]
            B = M12'*drV*M12
            A = dcF - M22'*drF*M22 - 1im*(GcrF*M22 - M22'*GrcF)
            ev = real(eigvals(A,B))
            positive_ev = ev[ev .> 0]
            tmax = isempty(positive_ev) ? Inf : minimum(positive_ev)
            e = min(1, tmax/2)
           
            GcrE = blkdiag(zeros(size(dcV,1),size(drV,1)),GcrF)
            DrE = blkdiag(e*drV,drF)
            DcE = blkdiag(e*dcV,dcF)
           
            A = MS'*DrE*MS + 1im*(GcrE*MS - MS'*GcrE') - blkdiag(zeros(size(dcV)),dcF)
            B = blkdiag(e*dcV,zeros(size(dcF)))
            ev = real(eigvals(A,B))
            finite_ev = ev[.!isinf.(ev) .&& .!isnan.(ev)]
            isempty(finite_ev) && return Inf,zeros(T,0,0),zeros(T,0,0),zeros(T,0,0)
            ubsq = maximum(finite_ev)
            Dr = zeros(T,size(M,1),size(M,1))
            Dc = zeros(T,size(M,2),size(M,2))
            Gcr = zeros(T,size(M,2),size(M,1))
           
            Dr[[FV[:VaryRows]; FV[:FixedRows]], [FV[:VaryRows]; FV[:FixedRows]]] = DrE
            Dc[[FV[:VaryCols]; FV[:FixedCols]], [FV[:VaryCols]; FV[:FixedCols]]] = DcE
            Gcr[[FV[:VaryCols]; FV[:FixedCols]],[FV[:VaryRows]; FV[:FixedRows]]] = GcrE
            ub = 1.01*sqrt(max(zero(ubsq),ubsq))
            (nAD <= 1) || (ub *= 5)
        else
            return Inf, zeros(T,0,0), zeros(T,0,0), zeros(T,0,0)
        end
    end
    return ub, Dr, Dc, Gcr
    # return Dict(:ub => ub, :Dr => Dr, :Dc => Dc, :Gcr => Gcr)
end

