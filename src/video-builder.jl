# This file is part of the QuickCharts.jl package. It is licensed under the MIT License.

"""
    VideoBuilder(;
        framerate=12,
        codec=nothing,
        cleanup=true,
        tempdir=nothing,
        freeze_scale=false,
        bounds_factor=1.0)

Accumulate `Figure` frames and encode them to a video with `save`.

# Arguments
- `framerate::Real`: output frame rate in frames per second.
- `codec::Union{Nothing,AbstractString}`: video codec passed to `ffmpeg`; `nothing` uses a format-dependent default.
- `cleanup::Bool`: remove temporary PNG frames after successful encoding.
- `tempdir::Union{Nothing,AbstractString}`: parent directory for the temporary frame directory; `nothing` uses the system temporary location.
- `freeze_scale::Bool`: reuse the scaling state from frame 1 for all frames.
- `bounds_factor::Real`: expand frozen bounds by this factor when `freeze_scale=true`.

# Notes
- `VideoBuilder` stores figure references exactly as they are passed to `add_frame`. If the same mutable figure is modified after being added, the saved video will reflect the later state.
- All frames must render to the same pixel size. `save(video, ...)` throws a `QuickChartsException` when frame sizes differ.
- Supported output formats are currently `.mp4` and `.avi`.

# Returns
- A `VideoBuilder` object.

# Example
```julia
using QuickCharts: VideoBuilder

video = VideoBuilder(framerate=12, freeze_scale=true, bounds_factor=1.05)
```
"""
mutable struct VideoBuilder
    frames::Vector{Figure}
    framerate::Float64
    codec::Union{Nothing,String}
    cleanup::Bool
    tempdir::Union{Nothing,String}
    freeze_scale::Bool
    bounds_factor::Float64

    function VideoBuilder(;
        framerate::Real=12.0,
        codec::Union{Nothing,AbstractString}=nothing,
        cleanup::Bool=true,
        tempdir::Union{Nothing,AbstractString}=nothing,
        freeze_scale::Bool=false,
        bounds_factor::Real=1.0,
    )
        framerate > 0 || throw(ArgumentError("framerate must be positive"))
        bounds_factor >= 1.0 || throw(ArgumentError("bounds_factor must be at least 1.0"))
        tempdir === nothing || !isempty(tempdir) || throw(ArgumentError("tempdir must be a non-empty string or nothing"))
        codec_string = codec === nothing ? nothing : string(codec)
        tempdir_string = tempdir === nothing ? nothing : string(tempdir)
        return new(Figure[], float(framerate), codec_string, cleanup, tempdir_string, freeze_scale, float(bounds_factor))
    end
end


function Base.show(io::IO, video::VideoBuilder)
    codec = video.codec === nothing ? "auto" : repr(video.codec)
    print(io, "VideoBuilder(frames=$(length(video.frames)), framerate=$(video.framerate), codec=$codec)")
end


Base.show(io::IO, ::MIME"text/plain", video::VideoBuilder) = show(io, video)


"""
    add_frame(video::VideoBuilder, figure::Figure)

Append one frame to `video`.
"""
function add_frame(video::VideoBuilder, figure::Figure)
    push!(video.frames, figure)
    return video
end


const _video_codec_defaults = Dict(
    ".mp4" => "libx264",
    ".avi" => "mpeg4",
)


function _video_extension(filename::AbstractString)
    _, ext = splitext(filename)
    ext = lowercase(ext)
    haskey(_video_codec_defaults, ext) || throw(QuickChartsException("Cannot save video to format $ext. Available formats are: .mp4 and .avi"))
    return ext
end


function _video_frame_dir(video::VideoBuilder)
    if video.tempdir === nothing
        return mktempdir(; prefix="quickcharts-video-", cleanup=false)
    else
        mkpath(video.tempdir)
        return mktempdir(video.tempdir; prefix="quickcharts-video-", cleanup=false)
    end
end


_video_frame_filename(frame_dir::AbstractString, i::Integer) = joinpath(frame_dir, @sprintf("frame-%06d.png", i))


function _video_frame_pixels(figure::Figure)
    width = round(Int, _png_raster_scale * figure.width)
    height = round(Int, _png_raster_scale * figure.height)
    return width, height
end


function _check_video_frame_sizes(video::VideoBuilder)
    width, height = _video_frame_pixels(video.frames[1])
    for (offset, frame) in enumerate(video.frames[2:end])
        i = offset + 1
        frame_width, frame_height = _video_frame_pixels(frame)
        if frame_width != width || frame_height != height
            throw(QuickChartsException("VideoBuilder frame $i has size $(frame_width) x $(frame_height) px, but frame 1 has size $(width) x $(height) px"))
        end
    end
    return width, height
end


function _video_codec(video::VideoBuilder, ext::AbstractString)
    return something(video.codec, _video_codec_defaults[ext])
end


_video_framerate_string(framerate::Real) = @sprintf("%.6f", framerate)


function _video_ffmpeg_args(video::VideoBuilder, ext::AbstractString, frame_dir::AbstractString, filename::AbstractString)
    codec = _video_codec(video, ext)
    args = String[
        "-y",
        "-hide_banner",
        "-loglevel",
        "error",
        "-framerate",
        _video_framerate_string(video.framerate),
        "-i",
        joinpath(frame_dir, "frame-%06d.png"),
        "-c:v",
        codec,
    ]

    if ext == ".mp4"
        append!(args, ["-vf", "pad=ceil(iw/2)*2:ceil(ih/2)*2", "-pix_fmt", "yuv420p"])
    end

    push!(args, filename)
    return args
end


function _video_freeze_state(video::VideoBuilder)
    video.freeze_scale || return nothing
    first_frame = video.frames[1]
    configure!(first_frame)
    return _capture_scaling_state(first_frame; bounds_factor=video.bounds_factor)
end


function _write_video_frames(video::VideoBuilder, frame_dir::AbstractString)
    freeze_state = _video_freeze_state(video)
    for (i, frame) in enumerate(video.frames)
        freeze_state === nothing || _apply_scaling_state!(frame, freeze_state)
        save(frame, _video_frame_filename(frame_dir, i))
    end
    return nothing
end


"""
    save(video::VideoBuilder, filename::AbstractString)

Encode the frames accumulated in `video` and write them to `filename`.

Supported output formats are `.mp4` and `.avi`. The target directory is created
automatically when needed. All frames must render to the same pixel size or
`save` throws a `QuickChartsException`.
"""
function save(video::VideoBuilder, filename::AbstractString)
    isempty(video.frames) && throw(QuickChartsException("VideoBuilder has no frames"))

    ext = _video_extension(filename)
    mkpath(dirname(filename))
    _check_video_frame_sizes(video)

    frame_dir = _video_frame_dir(video)
    success = false

    try
        _write_video_frames(video, frame_dir)
        args = _video_ffmpeg_args(video, ext, frame_dir, filename)
        FFMPEG.ffmpeg_exe(Cmd(args))
        success = true
    finally
        if video.cleanup && success
            rm(frame_dir; recursive=true, force=true)
        end
    end

    return nothing
end
