# Voxel Terrain
![Shader Ouput](output.png)

GPU implementation of the 'Voxel Space' algorithm (first pioneered by NovaLogic in the 1992 game *Comanche: Maximum Overkill*) in order to render voxel terrain using Rust and wgpu.

The algorithm takes in a height and a color map to efficiently generate a 2.5D from just a height and color map (overcoming the CPU limitations of the '90s to render graphics that were ahead of its time). For my GPU implementation, these were represented as textures, which were passed into the shader as a bind group, along with uniforms for camera values. Textures
also include sample in order to handle the repeating/periodic nature of the color and height maps.

```wgsl
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
```

The crux of the algorithm is also in the shader,
which is modified to work per pixel (instead of drawing lines) and also normalizes the texture values 
to UV coordinates in order to accurately sample it.

```wgsl
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
```

# Sources
'Learn Wgpu' by Ben Hansen https://sotrh.github.io/learn-wgpu/

'Terrain rendering algorithm in less than 20 lines of code' by Sebastian Macke https://github.com/s-macke/VoxelSpace