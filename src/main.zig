const std = @import("std");

const rl = @import("raylib");
const rgui = @import("raygui");

const window_title = "Noise Generator";

const initScreenWidth = 1600;
const initScreenHeight = 1000;

const padding = 10;

const noiseWidth = 0.75;

const State = struct {
    noise_type: i32,
    edit_noise_type: bool = false,

    ball_x: i32 = 20,
    ball_y: i32 = 40,
};

pub fn main() !void {
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
    });

    rl.initWindow(initScreenWidth, initScreenHeight, window_title);
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    var state = State{
        .noise_type = 0,
    };

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

    const width = screenWidth * noiseWidth - padding * 2;
    const height = screenHeight - padding * 2;

    rl.drawRectangleRoundedLines(rl.Rectangle.init(padding, padding, width, height), 0.01, 1, rl.Color.dark_blue);

    rl.drawCircle(state.ball_x, state.ball_y, 10, rl.Color.pink);
}

fn drawControls(state: *State) void {
    const screenWidth: f32 = @floatFromInt(rl.getScreenWidth());
    const screenHeight: f32 = @floatFromInt(rl.getScreenHeight());

    const x = screenWidth * noiseWidth + padding * 2;
    const y = padding;
    const width = screenWidth - x - padding;
    const height = screenHeight - padding * 2;

    _ = rgui.guiPanel(rl.Rectangle.init(x, y, width, height), "Controls");

    if (rgui.guiButton(rl.Rectangle.init(x + padding, y + 20 + padding + 40, 28, 28), "x") == 1) {
        state.ball_x += 10;
    }
    if (rgui.guiButton(rl.Rectangle.init(x + padding * 2 + 28, y + 20 + padding + 40, 28, 28), "y") == 1) {
        state.ball_y += 10;
    }

    const options = "perlin;simplex;white;other";
    if (rgui.guiDropdownBox(rl.Rectangle.init(x + padding, y + padding + 20, width - padding * 2, 28), options, &state.noise_type, state.edit_noise_type) == 1) {
        state.edit_noise_type = !state.edit_noise_type;
    }

    // _ = rgui.guiComboBox(rl.Rectangle.init(x + padding, y + 20 + padding + 80, width - padding * 2, 28), options, &active);
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
