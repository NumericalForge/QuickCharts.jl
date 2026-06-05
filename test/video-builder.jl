using QuickCharts
using Test
using Cairo: read_from_png, image_surface_get_data

first_pixel(filename) = unsafe_load(image_surface_get_data(read_from_png(filename)))

function solid_chart(color)
    chart = Chart(size=(4cm, 3cm), background=color)
    add_line(chart, [0.0, 1.0], [0.0, 1.0]; color=:black)
    return chart
end

function empty_grid()
    grid = ChartGrid(size=(4cm, 3cm), background=:old_paper)
    add_chart(grid, solid_chart(:old_paper), (1, 1))
    return grid
end

@test sprint(show, VideoBuilder()) == "VideoBuilder(frames=0, framerate=12.0, codec=auto)"

video = VideoBuilder()
@test_throws QuickCharts.QuickChartsException save(video, joinpath("output", "empty.mp4"))
@test_throws ArgumentError VideoBuilder(framerate=0)
@test_throws ArgumentError VideoBuilder(bounds_factor=0.9)

frame_root = joinpath("output", "video-builder-frames")
ispath(frame_root) && rm(frame_root; recursive=true, force=true)

push_video = VideoBuilder(framerate=2, cleanup=false, tempdir=frame_root)
add_frame(push_video, solid_chart(:white))
add_frame(push_video, solid_chart(:black))

mp4_file = joinpath("output", "video-builder.mp4")
save(push_video, mp4_file)
@test isfile(mp4_file)
@test filesize(mp4_file) > 0

frame_dirs = filter(isdir, joinpath.(Ref(frame_root), readdir(frame_root)))
@test length(frame_dirs) == 1
frame_files = sort(readdir(frame_dirs[1]))
@test frame_files == ["frame-000001.png", "frame-000002.png"]
@test first_pixel(joinpath(frame_dirs[1], frame_files[1])) != first_pixel(joinpath(frame_dirs[1], frame_files[2]))

cleanup_root = joinpath("output", "video-builder-cleanup")
ispath(cleanup_root) && rm(cleanup_root; recursive=true, force=true)

avi_video = VideoBuilder(framerate=3, cleanup=true, tempdir=cleanup_root)
add_frame(avi_video, solid_chart(:white))
add_frame(avi_video, empty_grid())

avi_file = joinpath("output", "video-builder.avi")
save(avi_video, avi_file)
@test isfile(avi_file)
@test filesize(avi_file) > 0
@test isempty(readdir(cleanup_root))

freeze_root = joinpath("output", "video-builder-freeze-frames")
ispath(freeze_root) && rm(freeze_root; recursive=true, force=true)

freeze_video = VideoBuilder(framerate=2, cleanup=false, tempdir=freeze_root, freeze_scale=true)
add_frame(freeze_video, solid_chart(:white))
add_frame(freeze_video, empty_grid())
freeze_file = joinpath("output", "video-builder-freeze.mp4")
save(freeze_video, freeze_file)
@test isfile(freeze_file)
@test filesize(freeze_file) > 0

freeze_dirs = filter(isdir, joinpath.(Ref(freeze_root), readdir(freeze_root)))
@test length(freeze_dirs) == 1
freeze_frame_files = sort(readdir(freeze_dirs[1]))
@test freeze_frame_files == ["frame-000001.png", "frame-000002.png"]
@test first_pixel(joinpath(freeze_dirs[1], freeze_frame_files[1])) != first_pixel(joinpath(freeze_dirs[1], freeze_frame_files[2]))

mixed_size_video = VideoBuilder()
add_frame(mixed_size_video, solid_chart(:white))
add_frame(mixed_size_video, Chart(size=(5cm, 3cm)))
@test_throws QuickCharts.QuickChartsException save(mixed_size_video, joinpath("output", "video-builder-size.mp4"))

bad_ext_video = VideoBuilder()
add_frame(bad_ext_video, solid_chart(:white))
@test_throws QuickCharts.QuickChartsException save(bad_ext_video, joinpath("output", "video-builder.mov"))
