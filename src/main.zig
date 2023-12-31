const std = @import("std");
const print = std.debug.print;
const testing = std.testing;
const parseInt = std.fmt.parseInt;

// This tool was inspired by https://autocompressor.net/tools/av1-calculator

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Parse args into string array (error union needs 'try')
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const NegError = error{IsNegative};

    const bitrateTarget = enum(u8) {
        lowest = 1,
        low = 2,
        med = 3,
        high = 4,
    };

    if (args.len == 1) { // if the user provided no args ...
        print("Please provide at least 4 arguments.\n", .{});
        print("Run `av1-tile-calc -h` for more info.\n", .{});
        return;
    }

    if (std.mem.eql(u8, args[1], "-h")) { // if the user provided `-h` ...
        _ = help(); // run the help function to print the help menu
        return;
    }

    // check if the user provided a negative integer
    var isNeg: i16 = undefined;
    for (args[1..4]) |arg| { // for every argument ...
        isNeg = try parseInt(i16, arg, 10); // parse each argument as an i16
        // if the argument is less than 0 (it is negative) ...
        if (isNeg < 0) {
            print("Please provide positive integers.\n", .{});
            print("Run `av1-tile-calc -h` for more info.\n", .{});
            return NegError.IsNegative;
        }
    }

    // too few args
    if (args.len < 5) {
        print("Please provide at least 4 arguments.\n", .{});
        print("Run `av1-tile-calc -h` for more info.\n", .{});
        return;
    }

    // too many args
    if (args.len > 5) {
        print("Please provide at most 4 arguments.\n", .{});
        print("Run `av1-tile-calc -h` for more info.\n", .{});
        return;
    }

    // user-provided bitrate range. maps to lowest, low, medium, and high
    var bitrate_range: bitrateTarget = undefined;

    if (std.mem.eql(u8, args[4], "lowest")) {
        bitrate_range = bitrateTarget.lowest;
    } else if (std.mem.eql(u8, args[4], "low")) {
        bitrate_range = bitrateTarget.low;
    } else if (std.mem.eql(u8, args[4], "med")) {
        bitrate_range = bitrateTarget.med;
    } else if (std.mem.eql(u8, args[4], "high")) {
        bitrate_range = bitrateTarget.high;
    } else {
        print("Please provide a proper bitrate target argument.\n", .{});
        return;
    }

    // calculate x-splits in Av1an based on user-provided fps. multiply it by 60 so it is easier to divide later
    var xs: usize = try parseInt(usize, args[3], 10);
    xs *= 60;

    // initialize the lag in frames variable
    var lif: usize = undefined;

    // set the x-splits & lag in frames based on the bitrate range
    switch (bitrate_range) {
        bitrateTarget.lowest => { // "lowest" bitrate target
            print("Bitrate Range: Lowest\n", .{});
            xs /= 3;
            lif = 64;
        },
        bitrateTarget.low => { // "low" bitrate target
            print("Bitrate Range: Low\n", .{});
            xs /= 4;
            lif = 48;
        },
        bitrateTarget.med => { // "medium" bitrate target
            print("Bitrate Range: Medium\n", .{});
            xs /= 6;
            lif = 48;
        },
        bitrateTarget.high => { // "high" bitrate target
            print("Bitrate Range: High\n", .{});
            xs /= 6;
            lif = 48;
        },
    }

    // Parse target width & height from the first & second args
    const width: usize = try parseInt(usize, args[1], 10);
    const height: usize = try parseInt(usize, args[2], 10);

    // Target pixels per tile (actual result will be ≥2/3 and <4/3 of this number)
    const tpx: usize = 2000000;

    // initialize rows log 2 & columns log 2
    var rowsl: usize = 0;
    var colsl: usize = 0;

    var ctpx: usize = width * height; // current tile pixels, starts at the full size of the video, we subdivide until <4/3 of tpx
    var ctar: usize = width / height; // current tile aspect ratio, we subdivide into cols if >1 and rows if ≤1

    _ = getTiles(tpx, &rowsl, &colsl, &ctpx, &ctar);

    // initialize literal columns & literal rows
    const cols: usize = std.math.pow(usize, 2, colsl);
    const rows: usize = std.math.pow(usize, 2, rowsl);

    // print results
    print("Tile Columns:\n", .{});
    print("\tLog-2:   {d}\n", .{colsl});
    print("\tLiteral: {d}\n", .{cols});

    print("Tile Rows:\n", .{});
    print("\tLog-2:   {d}\n", .{rowsl});
    print("\tLiteral: {d}\n", .{rows});

    print("X-splits:\t {d}\n", .{xs});
    print("Lag in Frames:\t {d}\n", .{lif});
}

fn getTiles(tpx: usize, rowsl_ptr: *usize, colsl_ptr: *usize, ctpx_ptr: *usize, ctar_ptx: *usize) void {
    // tpx = 2,000,000 results in 1 tile at 1080p, tpx = 1,000,000 results in 2 tiles at 1080p

    // while current tile pixels >= pixels per tile * 4/3
    while (ctpx_ptr.* >= tpx * 4 / 3) {
        if (ctar_ptx.* > 1) {
            // Subdivide into columns, add 1 to colsl and halve ctar, then halve ctpx
            colsl_ptr.* += 1;
            ctar_ptx.* /= 2;
            ctpx_ptr.* /= 2;
        } else {
            // Subdivide into rows, add 1 to rowsl and double ctar, then halve ctpx
            rowsl_ptr.* += 1;
            ctar_ptx.* *= 2;
            ctpx_ptr.* /= 2;
        }
    }
}

fn help() void {
    // Contains print statements for the help menu
    print("AV1 Tile Calculator | inspired by autocompressor.net/tools/av1-calculator\n", .{});
    print("Usage: av1-tile-calc [width] [height] [fps] [bitrate_range]\n", .{});
    print("\n", .{});
    print("Options:\n", .{});
    print("\tWidth:\t\tYour input width in pixels\n", .{});
    print("\tHeight:\t\tYour input height in pixels\n", .{});
    print("\tfps:\t\tYour input frames per second\n", .{});
    print("\tBitrate Range:\tAccepts `lowest`, `low`, `med`, `high`\n", .{});
    print("\n", .{});
    print("Output:\n", .{});
    print("\tLog-2:", .{});
    print("\t\tUseful for aomenc & SVT-AV1\n", .{});
    print("\tLiteral:", .{});
    print("\tUseful for libaom-av1 & rav1e\n", .{});
    print("\tX-split length:", .{});
    print("\tThe -x (--extra-splits) option in Av1an\n", .{});
    print("\tLag in Frames:", .{});
    print("\tUseful for aom-av1-lavish & other forks\n", .{});
    return;
}

test "getTiles" {
    var testrowsl: usize = 0;
    var testcolsl: usize = 0;

    var testctpx: usize = 1920 * 1080;
    var testctar: usize = 1920 / 1080;
    var testtpx: usize = 2000000;

    _ = getTiles(testtpx, &testrowsl, &testcolsl, &testctpx, &testctar);

    try testing.expect(testrowsl == 0);
    try testing.expect(testcolsl == 0);
}
