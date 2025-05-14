# Voxel Terrain
GPU implementation of the 'Voxel Space' algorithm (first pioneered by NovaLogic in the 1992 game *Comanche: Maximum Overkill*) to render voxel terrain using Rust and wgpu.

The algorithm takes in a height and a color map to efficiently generate a 2.5D from just a 
height and color map (overcoming the CPU limitations of the '90s to render graphics that were ahead of its time). For my GPU implementation, these 

# Sources
'Learn Wgpu' by Ben Hansen https://sotrh.github.io/learn-wgpu/

'Terrain rendering algorithm in less than 20 lines of code' by Sebastian Macke https://github.com/s-macke/VoxelSpace