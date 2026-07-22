from gradio_client import Client, handle_file



client = Client("shalomreuel/TRELLIS.2-Text-to-3D")
print(client.view_api())
image = handle_file(
    r"D:\Shalom Essentials\Game development\gene\generated_creature.png"
)

# Generate the 3D model
result = client.predict(
    image,
    0,
    "512",      # resolution
    50000,      # decimation_target
    512,        # texture_size
    5.0,        # ss_guidance_strength
    0.5,        # ss_guidance_rescale
    4,          # ss_sampling_steps
    3.0,        # ss_rescale_t
    5.0,        # shape_guidance
    0.5,        # shape_rescale
    4,          # shape_steps
    3.0,        # shape_rescale_t
    1.0,        # tex_guidance
    0.0,        # tex_rescale
    4,          # tex_steps
    3.0,        # tex_rescale_t
    api_name="/generate_3d"
)

viewer_data, glb_file = result

print("Viewer:", viewer_data)
print("GLB:", glb_file)