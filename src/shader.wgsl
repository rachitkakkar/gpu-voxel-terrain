// https://sotrh.github.io/learn-wgpu/beginner/tutorial5-textures/#pipelinelayout
// https://raytracing.github.io/gpu-tracing/book/RayTracingGPUEdition.html
// https://github.com/melchor629/raycastergl/tree/master
// https://www.shadertoy.com/view/4dG3RD -> Chrome

// Vertex shader

struct VertexOutput {
    @builtin(position) pos: vec4<f32>,
};

var<private> quad: array<vec2f, 6> = array<vec2f, 6>(
  vec2f(-1.0,  1.0),
  vec2f(-1.0, -1.0),
  vec2f( 1.0,  1.0),
  vec2f( 1.0,  1.0),
  vec2f(-1.0, -1.0),
  vec2f( 1.0, -1.0),
);

@vertex
fn vs_main(
    @builtin(vertex_index) in_vertex_index: u32,
) -> VertexOutput {
    var out: VertexOutput;
    out.pos = vec4<f32>(quad[in_vertex_index], 0.0, 1.0);
    return out;
}

// Fragment shader

struct CameraUniform {
    p: vec2<f32>,
    height: f32,
    angle: f32,
    screen_width: u32,
    screen_height: u32,
};

@group(0) @binding(0)
var<uniform> camera: CameraUniform;
@group(1) @binding(0)
var t_height_map: texture_2d<f32>;
@group(1) @binding(1)
var s_height_map: sampler;
@group(2) @binding(0)
var t_color_map: texture_2d<f32>;
@group(2) @binding(1)
var s_color_map: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let horizon = f32(camera.screen_height / 2);
    let scale_factor = f32(camera.screen_height * 2);
    let sinPhi = sin(camera.angle);
    let cosPhi = cos(camera.angle);
    let distance = 1000.0;

    let uv = in.pos.xy / vec2<f32>(f32(camera.screen_width), f32(camera.screen_height)) + 0.5;
    var color = vec4<f32>(0.5f * uv.y, 0.7f * uv.y, 1.0f, 0.0f);

    let map_size = textureDimensions(t_height_map).xy;
    for (var z = distance; z > 1.0; z = z - 0.5) {
        let pleft = vec2<f32>(-cosPhi * z - sinPhi * z + camera.p.x,
            sinPhi * z - cosPhi * z + camera.p.y);
        let pright =  vec2<f32>(cosPhi * z - sinPhi * z + camera.p.x,
            -cosPhi * z - cosPhi * z + camera.p.y);

        let dx = (pright - pleft) / f32(camera.screen_width);
        var current = pleft + in.pos.x * dx;

        let map_uv = (current.xy / vec2<f32>(f32(map_size.x - 1u), f32(map_size.y - 1u)));
        let height_val = textureSample(t_height_map, s_height_map, map_uv).r * 255.0;
        let height_on_screen = ((camera.height - height_val) / z) * scale_factor + horizon;

        if (height_on_screen < in.pos.y) {
            color = textureSample(t_color_map, s_height_map, map_uv);
        }
    }

    return color;
}