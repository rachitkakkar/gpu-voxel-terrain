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
    width: u32,
    height: u32,
};
@group(0) @binding(0)
var<uniform> camera: CameraUniform;

@group(1) @binding(0)
var t_height_map: texture_2d<f32>;
@group(1) @binding(1)
var s_height_map: sampler;

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.pos.xy / vec2f(f32(camera.width - 1u), f32(camera.height - 1u));
    return textureSample(t_height_map, s_height_map, uv);
}