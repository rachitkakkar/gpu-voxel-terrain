// https://sotrh.github.io/learn-wgpu/beginner/tutorial5-textures/#pipelinelayout
// https://raytracing.github.io/gpu-tracing/book/RayTracingGPUEdition.html
// https://github.com/melchor629/raycastergl/tree/master
// https://www.shadertoy.com/view/4dG3RD -> Chrome

// Vertex shader
struct VertexOutput {
    @builtin(position) pos: vec4<f32>,
};

var<private> vertices: array<vec2f, 6> = array<vec2f, 6>(
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
    out.pos = vec4<f32>(vertices[in_vertex_index], 0.0, 1.0);
    return out;
}

// Fragment shader
@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let color = in.pos.xy / vec2f(f32(800 - 1u), f32(600 - 1u));
    return vec4<f32>(color, 0.1, 1.0);
}