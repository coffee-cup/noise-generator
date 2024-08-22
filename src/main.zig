const std = @import("std");

const rl = @import("raylib");
const rgui = @import("raygui");

const window_title = "Noise Generator";

const initScreenWidth = 1200;
const initScreenHeight = 800;

const padding = 10;

const noiseWidth = initScreenWidth - controlsWidth;
const controlsWidth = 360;

const NoiseType = enum {
    random,
    perlin,
};

const RandomNoiseConfig = struct {
    animate: bool = false,
    scale: f32 = @floatFromInt(noiseWidth),
};

const PerlinNoiseConfig = struct {
    animate: bool = false,
    scale: f32 = @floatFromInt(noiseWidth),
    octaves: u32 = 4,
};

const NoiseConfig = union(NoiseType) {
    random: RandomNoiseConfig,
    perlin: PerlinNoiseConfig,
};

const default_noise: NoiseType = .random;

const State = struct {
    shader: rl.Shader,
    noise_texture: rl.RenderTexture2D,
    noise_type: NoiseType = default_noise,
    noise_config: NoiseConfig = .{ .perlin = .{} },
    noise_type_index: i32 = @intFromEnum(default_noise),
    edit_noise_type: bool = false,
    font: rl.Font,
};

const Style = struct {
    controlId: i32,
    propertyId: i32,
    colorValue: u32,
};

const DEFAULT_TEXT_SIZE: u8 = 18;

const style = [_]Style{
    .{ .controlId = 0, .propertyId = 0, .colorValue = 0xe58b68ff }, // DEFAULT_BORDER_COLOR_NORMAL
    .{ .controlId = 0, .propertyId = 1, .colorValue = 0xffb426ff }, // DEFAULT_BASE_COLOR_NORMAL
    .{ .controlId = 0, .propertyId = 2, .colorValue = 0xa34a02ff }, // DEFAULT_TEXT_COLOR_NORMAL
    .{ .controlId = 0, .propertyId = 3, .colorValue = 0xee813fff }, // DEFAULT_BORDER_COLOR_FOCUSED
    .{ .controlId = 0, .propertyId = 4, .colorValue = 0xfcd85bff }, // DEFAULT_BASE_COLOR_FOCUSED
    .{ .controlId = 0, .propertyId = 5, .colorValue = 0xfc6955ff }, // DEFAULT_TEXT_COLOR_FOCUSED
    .{ .controlId = 0, .propertyId = 6, .colorValue = 0xb34848ff }, // DEFAULT_BORDER_COLOR_PRESSED
    .{ .controlId = 0, .propertyId = 7, .colorValue = 0x8a014aff }, // DEFAULT_BASE_COLOR_PRESSED
    .{ .controlId = 0, .propertyId = 8, .colorValue = 0xff91ccff }, // DEFAULT_TEXT_COLOR_PRESSED
    .{ .controlId = 0, .propertyId = 9, .colorValue = 0x94795dff }, // DEFAULT_BORDER_COLOR_DISABLED
    .{ .controlId = 0, .propertyId = 10, .colorValue = 0xc2a37aff }, // DEFAULT_BASE_COLOR_DISABLED
    .{ .controlId = 0, .propertyId = 11, .colorValue = 0x9c8369ff }, // DEFAULT_TEXT_COLOR_DISABLED
    .{ .controlId = 0, .propertyId = 16, .colorValue = DEFAULT_TEXT_SIZE },
    .{ .controlId = 0, .propertyId = 17, .colorValue = 0x00000000 },
    .{ .controlId = 0, .propertyId = 18, .colorValue = 0xd77575ff }, // DEFAULT_LINE_COLOR
    .{ .controlId = 0, .propertyId = 19, .colorValue = 0xfff5e1ff }, // DEFAULT_BACKGROUND_COLOR
    .{ .controlId = 0, .propertyId = 20, .colorValue = 0x00000015 },
};

pub fn main() !void {
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = false,
    });

    rl.initWindow(initScreenWidth, initScreenHeight, window_title);
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    // Load style properties provided
    for (style) |prop| {
        const color = rl.getColor(prop.colorValue);
        rgui.guiSetStyle(prop.controlId, prop.propertyId, color.toInt());
    }

    var state = State{
        .shader = rl.loadShader(null, "resources/noise.fs"),
        .noise_texture = rl.loadRenderTexture(@intFromFloat(initScreenWidth - controlsWidth), initScreenHeight - padding * 2),
        .font = rl.loadFont("resources/JetBrainsMono.ttf"),
        .noise_type = default_noise,
    };

    if (state.noise_type == .perlin) {
        state.noise_config = .{ .perlin = .{} };
    } else if (state.noise_type == .random) {
        state.noise_config = .{ .random = .{} };
    }

    defer rl.unloadShader(state.shader);
    defer rl.unloadRenderTexture(state.noise_texture);
    defer rl.unloadFont(state.font);

    // Set the font for raygui
    rgui.guiSetFont(state.font);

    // Set font texture filter mode to BILINEAR
    rl.setTextureFilter(state.font.texture, .texture_filter_bilinear);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();

        rl.clearBackground(rl.Color.black);

        drawNoise(&state);
        drawControls(&state);

        rl.endDrawing();
    }
}

fn drawNoise(state: *State) void {
    const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());

    const width = screenWidth - controlsWidth;
    const height = screenHeight - padding * 2;

    // Update noise texture size if window is resized
    if (state.noise_texture.texture.width != @as(c_int, @intFromFloat(width)) or
        state.noise_texture.texture.height != @as(c_int, @intFromFloat(height)))
    {
        rl.unloadRenderTexture(state.noise_texture);
        state.noise_texture = rl.loadRenderTexture(@intFromFloat(width), @intFromFloat(height));
    }

    const noise_type: f32 = @floatFromInt(state.noise_type_index);
    const resolution = [2]f32{ width, height };

    // Set shader uniforms
    rl.setShaderValue(state.shader, rl.getShaderLocation(state.shader, "resolution"), &resolution, .shader_uniform_vec2);
    rl.setShaderValue(state.shader, rl.getShaderLocation(state.shader, "noiseType"), &noise_type, .shader_uniform_float);

    switch (state.noise_config) {
        .random => |*config| {
            rl.setShaderValue(state.shader, rl.getShaderLocation(state.shader, "scale"), &config.scale, .shader_uniform_float);
        },
        .perlin => |*config| {
            rl.setShaderValue(state.shader, rl.getShaderLocation(state.shader, "scale"), &config.scale, .shader_uniform_float);
        },
    }

    // Render noise to texture
    rl.beginTextureMode(state.noise_texture);
    rl.clearBackground(rl.Color.black);
    rl.beginShaderMode(state.shader);
    rl.drawRectangle(0, 0, @intFromFloat(width), @intFromFloat(height), rl.Color.white);
    rl.endShaderMode();
    rl.endTextureMode();

    // Draw noise texture
    rl.drawTexturePro(state.noise_texture.texture, rl.Rectangle.init(0, 0, width, -height), rl.Rectangle.init(padding, padding, width, height), .{ .x = 0, .y = 0 }, 0.0, rl.Color.white);
}

fn drawControls(state: *State) void {
    const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
    // const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());

    const x = screenWidth - controlsWidth + padding * 2;
    const y = padding;
    const width = controlsWidth - padding * 3;
    // const height = screenHeight - padding * 2;

    // rl.drawText("Controls", @intFromFloat(x + padding), y, 20, rl.Color.white);
    // rl.drawTextEx(state.font, "Controls", .{ .x = x + padding, .y = y }, 32, 0, rl.Color.white); // Increased font size

    // _ = rgui.guiPanel(rl.Rectangle.init(x, y, width, 60), "Noise Type");
    const groupBoxHeight = 28;
    _ = rgui.guiGroupBox(rl.Rectangle.init(x, y + 20, width, groupBoxHeight + padding * 2), "Noise Type");

    switch (state.noise_config) {
        .random => |*config| {
            const randomBoxHeight = 60;
            const innerControlsWidth = width - padding * 2;

            _ = rgui.guiGroupBox(rl.Rectangle.init(x, y + 20 + groupBoxHeight + padding * 4, width, randomBoxHeight + padding * 2), "Random Noise Config");

            var buffer: [32:0]u8 = undefined;
            const scale_text = std.fmt.bufPrintZ(&buffer, "{d:.0}", .{config.scale}) catch unreachable;

            _ = rgui.guiSlider(rl.Rectangle.init(x + padding + 40, y + 20 + groupBoxHeight + padding * 5, innerControlsWidth - 58, 20), "Scale", scale_text, &config.scale, 2.0, @floatFromInt(noiseWidth));
        },
        .perlin => |*config| {
            std.debug.print("Perlin Noise Config: {}\n", .{config});
            // rgui.guiSliderBar(rl.Rectangle.init(x + padding, y + 20 + padding + groupBoxHeight + padding, width - padding * 2, 28), "Octaves", "Octaves", &state.noise_config.perlin.octaves, 0, 100);
        },
    }

    // _ = rgui.guiPanel(rl.Rectangle.init(x, y, width, height), "Controls");

    // if (rgui.guiButton(rl.Rectangle.init(x + padding, y + 20 + padding + 40, 28, 28), "x") == 1) {
    //     state.ball_x += 10;
    // }
    // if (rgui.guiButton(rl.Rectangle.init(x + padding * 2 + 28, y + 20 + padding + 40, 28, 28), "y") == 1) {
    //     state.ball_y += 10;
    // }

    // _ = rgui.guiComboBox(rl.Rectangle.init(x + padding, y + 20 + padding + 80, width - padding * 2, 28), options, &active);

    const options = "random;perlin";
    if (rgui.guiDropdownBox(rl.Rectangle.init(x + padding, y + 20 + padding, width - padding * 2, groupBoxHeight), options, &state.noise_type_index, state.edit_noise_type) == 1) {
        state.edit_noise_type = !state.edit_noise_type;
        state.noise_type = @as(NoiseType, @enumFromInt(state.noise_type_index));

        if (state.noise_type == .random) {
            state.noise_config = .{ .random = .{} };
        } else {
            state.noise_config = .{ .perlin = .{} };
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
