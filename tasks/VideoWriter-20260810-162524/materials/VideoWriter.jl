"""
VideoWriter - 创建对象以写入视频文件

v = VideoWriter(filename, profile)

v = VideoWriter(filename,[Width Height])

v = VideoWriter(filename,[Width Height],FrameRate)
"""
mutable struct VideoWriter
    _vw::Union{PyObject,Nothing}
    FileName::AbstractString
    Path::AbstractString
    FileFormat::AbstractString
    Duration::Float64

    ColorChannels::Int
    Height::Int
    Width::Int
    FrameCount::UInt64
    FrameRate::Real
    VideoBitsPerPixel::Int
    VideoFormat::AbstractString
    VideoCompressionMethod::AbstractString
    Quality::Int
    _set_enable::Bool
    _is_open::Bool

    function VideoWriter(file::AbstractString, profile::AbstractString)
        fn_, pth, fmt, compression_method = _video_writer_file_info(file, profile)

        return new(
            nothing,
            fn_,
            pth,
            fmt,
            0,
            3,
            0,
            0,
            0,
            30,
            24,
            "RGB24",
            compression_method,
            75,
            false,
            false,
        )
    end

    function VideoWriter(
        file::AbstractString,
        frm_size::AbstractArray{Int},
        fps::Real=30;
        profile::AbstractString="Motion JPEG AVI",
    )
        fn_, pth, fmt, compression_method = _video_writer_file_info(file, profile)
        err_sz_info = @tr(
            "The input video frame size must be a two-element vector of positive integers."
        )
        if length(frm_size) != 2
            error(_msg(err_sz_info, splitext(basename(@__FILE__))[1]))
        end
        if any(frm_size .<= 0)
            error(_msg(err_sz_info, splitext(basename(@__FILE__))[1]))
        end

        if fps <= 0
            err_sz_info = @tr("Frame rate must be positive.")
            error(_msg(err_sz_info, splitext(basename(@__FILE__))[1]))
        end

        abs_p = pth * "\\" * fn_

        obj = _py_init_video_writer(abs_p, fps, frm_size)

        return new(
            obj,
            fn_,
            pth,
            fmt,
            0,
            3,
            frm_size[2],
            frm_size[1],
            0,
            fps,
            24,
            "RGB24",
            compression_method,
            75,
            false,
            false,
        )
    end

    function _py_init_video_writer(file, fps, frm_sz)
        _set_python_path()
        py"""
        from images.mw_videowriter import cv_init_video_writer
        """
        return py"cv_init_video_writer"(file, fps, (frm_sz[1], frm_sz[2]))
    end
end

function _video_writer_file_info(file::AbstractString, profile::AbstractString)
    if isempty(file)
        error(_msg(@tr("Input must be non-empty."), splitext(basename(@__FILE__))[1]))
    end

    dir_nm = dirname(file)
    pth = isempty(dir_nm) ? pwd() : dir_nm
    if lowercase(profile) == lowercase("Motion JPEG AVI")
        fmt = ".avi"
        compression_method = "Motion JPEG"
    elseif lowercase(profile) == lowercase("MPEG-4")
        fmt = ".mp4"
        compression_method = "H.264"
    else
        fmt = ".avi"
        compression_method = "Motion JPEG"
    end
    fn_ = splitext(basename(file))[1] * fmt
    return fn_, pth, fmt, compression_method
end

function Base.setproperty!(vd::VideoWriter, symb::Symbol, val_::Real)
    if symb === :FrameRate
        if vd._is_open
            error(
                _msg(
                    @tr(
                        "Cannot modify the FrameRate property of a VideoWriter object after calling OPEN."
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if val_ < 0
            error(
                _msg(@tr("FrameRate must be positive."), splitext(basename(@__FILE__))[1])
            )
        end
        res = Float64(val_)
    elseif symb === :Quality
        if vd._is_open
            error(
                _msg(
                    @tr(
                        "Cannot modify the Quality property of a VideoWriter object after calling OPEN."
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        if val_ < 0
            error(
                _msg(
                    @tr("Quality must be a scalar with value >= 0."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        elseif round(val_, RoundNearestTiesAway) != val_
            error(
                _msg(@tr("Quality must be an integer value.")),
                splitext(basename(@__FILE__))[1],
            )
        elseif val_ > 100
            error(
                _msg(
                    @tr("Quality must be a scalar with value <= 100."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
        res = Int(val_)
    elseif symb === :FrameCount
        if vd._set_enable
            res = round(UInt64, val_)
        else
            error(
                _msg(
                    @tr(
                        "Cannot set property \"%{1}\" of \"VideoWriter\" because it is read-only.",
                        symb
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    elseif symb === :Duration
        if vd._set_enable
            res = val_
        else
            error(
                _msg(
                    @tr(
                        "Cannot set property \"%{1}\" of \"VideoWriter\" because it is read-only.",
                        symb
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    else
        if symb ∈ fieldnames(typeof(vd))
            error(
                _msg(
                    @tr(
                        "Cannot set property \"%{1}\" of \"VideoWriter\" because it is read-only.",
                        symb
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        else
            error(
                _msg(
                    @tr("Unrecognized property \"%{1}\" for type \"VideoWriter\".", symb),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    return setfield!(vd, symb, res)
end

function Base.setproperty!(vd::VideoWriter, symb::Symbol, val_::Bool)
    if symb === :_set_enable || symb === :_is_open
        return setfield!(vd, symb, val_)
    else
        error(
            _msg(
                @tr("Unrecognized property \"%{1}\" for type \"VideoWriter\".", symb),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
end

function Base.setproperty!(vd::VideoWriter, symb::Symbol, val_::AbstractString)
    if symb ∈ fieldnames(typeof(vd))
        error(
            _msg(
                @tr(
                    "Cannot set property \"%{1}\" of \"VideoWriter\" because it is read-only.",
                    symb
                ),
                splitext(basename(@__FILE__))[1],
            ),
        )
    else
        error(
            _msg(
                @tr("Unrecognized property \"%{1}\" for type \"VideoWriter\".", symb),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end
end

#####################################################################
##                        Display Functions                        ##
#####################################################################
Base.print(io::IO, v::VideoWriter) = show(io, v)

function Base.show(io::IO, v::VideoWriter)
    println(@tr("\nVideoWriter - properties:\n"))
    println(@tr("General properties:"))
    println(@tr("\tFileName (file name): \"%{1}\"", v.FileName))
    println(@tr("\tPath (directory): \"%{1}\"", v.Path))
    println(@tr("\tFileFormat (format): \"%{1}\"", v.FileFormat))
    println(@tr("\tDuration (seconds): %{1}", v.Duration))

    println(@tr("\nVideo properties:\n"))
    println(@tr("\tColorChannels (channels): %{1}", v.ColorChannels))
    println(@tr("\tHeight (pixels): %{1}", v.Height))
    println(@tr("\tWidth (pixels): %{1}", v.Width))
    println(@tr("\tFrameCount (frames): %{1}", v.FrameCount))
    println(@tr("\tFrameRate (frames per second): %{1}", v.FrameRate))
    println(@tr("\tVideoBitsPerPixel (bits per pixel): %{1}", v.VideoBitsPerPixel))
    println(@tr("\tVideoFormat (format): %{1}", v.VideoFormat))
    println(@tr("\tVideoCompressionMethod (compression): %{1}", v.VideoCompressionMethod))
    return println(@tr("\tQuality: %{1}", v.Quality))
end

function Base.open(vd::VideoWriter)
    if vd._is_open
        return nothing
    end

    _ensure_vw_py_funcs!()
    vd._set_enable = true
    vd.Duration = 0.0
    vd.FrameCount = 0
    vd._set_enable = false

    if vd.Width > 0 && vd.Height > 0
        save_f = joinpath(vd.Path, vd.FileName)
        if vd._vw !== nothing
            _VW_RELEASE_VIDEO_WRITER[](vd._vw)
        end
        vd._vw = _VW_CV_INIT_VIDEO_WRITER[](save_f, vd.FrameRate, (vd.Width, vd.Height))
        _VW_SET_VIDEO_OPEN[](vd._vw)
    end
    vd._is_open = true
    return nothing
end

function writeVideo(
    vd::VideoWriter, frm::AbstractArray{T}
) where {T<:Union{MInteger,MFloat,Bool}}
    if !vd._is_open
        error(
            _msg(
                @tr("You must open the VideoWriter object before calling writeVideo."),
                splitext(basename(@__FILE__))[1],
            ),
        )
    end

    if !(2 <= ndims(frm) <= 4)
        err_info = @tr("IMG must be a 2-D, 3-D, or 4-D grayscale/RGB array.")
        throw(ArgumentError(err_info))
    end
    if ndims(frm) == 3 && size(frm, 3) != 3
        err_info = @tr("The third dimension of an RGB video frame must have size 3.")
        throw(ArgumentError(err_info))
    end

    if ndims(frm) == 4 && !(size(frm, 3) == 1 || size(frm, 3) == 3)
        err_info = @tr("The third dimension of a video frame array must have size 1 or 3.")
        throw(ArgumentError(err_info))
    end

    if (vd.Width != 0 || vd.Height != 0) && size(frm)[1:2] != (vd.Height, vd.Width)
        err_info = @tr(
            "IMG must be a grayscale/RGB array of size %{1}x%{2} or %{1}x%{2}x3, or a grayscale/RGB array of size %{1}x%{2}x1xN or %{1}x%{2}x3xN.",
            vd.Height,
            vd.Width,
        )
        throw(ArgumentError(err_info))
    end

    if eltype(frm) == Float32 || eltype(frm) == Float64
        if any(frm .> 1 .|| frm .< 0)
            error(
                _msg(
                    @tr(
                        "Video frames of type %{1} must have values in the range [0, 1].",
                        string(eltype(frm))
                    ),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    if vd.Width == 0 && vd.Height == 0
        setfield!(vd, :Height, size(frm, 1))
        setfield!(vd, :Width, size(frm, 2))
    end

    if vd._vw === nothing
        _ensure_vw_py_funcs!()
        save_f = joinpath(vd.Path, vd.FileName)
        vd._vw = _VW_CV_INIT_VIDEO_WRITER[](save_f, vd.FrameRate, (vd.Width, vd.Height))
        _VW_SET_VIDEO_OPEN[](vd._vw)
    end

    py"""
    from images.mw_videowriter import write_frame
    """
    function write_gray_frm(frm)
        frm1 = im2uint8(frm)
        rgb_ = zeros(UInt8, size(frm, 1), size(frm, 2), 3)
        rgb_[:, :, 1] = frm1
        rgb_[:, :, 2] = frm1
        rgb_[:, :, 3] = frm1
        res = py"write_frame"(vd._vw, rgb_)
        if !res
            error(
                _msg(
                    @tr("The video file has been closed and must be recreated."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    function write_rgb_frm(frm)
        rgb_ = zeros(UInt8, size(frm))
        rgb_[:, :, 1] = frm[:, :, 3]
        rgb_[:, :, 2] = frm[:, :, 2]
        rgb_[:, :, 3] = frm[:, :, 1]
        res = py"write_frame"(vd._vw, im2uint8(rgb_))
        if !res
            error(
                _msg(
                    @tr("The video file has been closed and must be recreated."),
                    splitext(basename(@__FILE__))[1],
                ),
            )
        end
    end

    vd._set_enable = true
    if ndims(frm) == 2
        frm = im2uint8(frm)
        write_gray_frm(frm)
        vd.FrameCount = vd.FrameCount + 1
        vd.Duration = vd.FrameCount * 1.0 / vd.FrameRate
    elseif ndims(frm) == 3
        frm = im2uint8(frm)
        write_rgb_frm(frm)
        vd.FrameCount = vd.FrameCount + 1
        vd.Duration = vd.FrameCount * 1.0 / vd.FrameRate
    elseif ndims(frm) == 4
        if size(frm, 3) == 1
            func_ = write_gray_frm
        else
            func_ = write_rgb_frm
        end
        nfrm = size(frm, 4)
        for idx in 1:nfrm
            fu8 = im2uint8(frm[:, :, :, idx])
            func_(fu8)
        end

        vd.FrameCount = vd.FrameCount + nfrm
        vd.Duration = vd.FrameCount * 1.0 / vd.FrameRate
    end
    vd._set_enable = false
    return nothing
end

writeVideo(vd, frame::Frame_struct) = writeVideo(vd, frame.cdata)

function Base.close(vd::VideoWriter)
    if !vd._is_open
        return nothing
    end

    vd._is_open = false
    if vd.FrameCount < 1
        @warn @tr(
            "No video frames have been written to this file; the file may be invalid."
        )
    end
    if vd._vw === nothing
        return nothing
    end

    _ensure_vw_py_funcs!()
    return _VW_RELEASE_VIDEO_WRITER[](vd._vw)
end

const _VW_GET_VIDEO_OPEN = Ref{Any}(nothing)
const _VW_RELEASE_VIDEO_WRITER = Ref{Any}(nothing)
const _VW_CV_INIT_VIDEO_WRITER = Ref{Any}(nothing)
const _VW_SET_VIDEO_OPEN = Ref{Any}(nothing)

function _ensure_vw_py_funcs!()
    if _VW_GET_VIDEO_OPEN[] === nothing ||
        _VW_RELEASE_VIDEO_WRITER[] === nothing ||
        _VW_CV_INIT_VIDEO_WRITER[] === nothing ||
        _VW_SET_VIDEO_OPEN[] === nothing
        _set_python_path()
        py"""
        from images.mw_videowriter import (
            cv_init_video_writer,
            set_video_open,
            get_video_open,
            release_video_writer,
        )
        """
        _VW_CV_INIT_VIDEO_WRITER[] = py"cv_init_video_writer"
        _VW_SET_VIDEO_OPEN[] = py"set_video_open"
        _VW_GET_VIDEO_OPEN[] = py"get_video_open"
        _VW_RELEASE_VIDEO_WRITER[] = py"release_video_writer"
    end
    return nothing
end
