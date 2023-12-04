const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn parse_file(allocator: Allocator, input_file: []const u8) !std.AutoHashMap(u32, [][3] u8) {
    var games = std.AutoHashMap(u32, [][3] u8).init(allocator);
    var file = try std.fs.cwd().openFile(input_file, .{});
    defer file.close();

    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();

    var buf: [1024]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var my_shows: std.ArrayList([3]u8) = std.ArrayList([3]u8).init(allocator);
        var top_split = std.mem.split(u8, line, ":");
        var game_part: []const u8  = top_split.next().?;
        var game_split = std.mem.split(u8, game_part, " ");
        _ = game_split.next();
        var game_number: u32 = try std.fmt.parseInt(u32, game_split.next().?, 10);
        std.debug.print("top_split: {s} {d}\n", .{game_part, game_number});
        var cube_split = std.mem.split(u8, top_split.next().?, ";");
        while (cube_split.next()) |show| {
            var single_show = [3]u8 {0, 0, 0};  // RGB
            std.debug.print("  show: {s}\n", .{show});
            var show_split = std.mem.split(u8, show, ",");
            while (show_split.next()) |count_color| {
                std.debug.print("    color: {s}", .{count_color});
                var count_color_split = std.mem.split(u8, count_color[1..], " ");
                var count = try std.fmt.parseInt(u8, count_color_split.next().?, 10);
                var color = count_color_split.next().?;
                if (std.mem.eql(u8, color, "red")) {
                    single_show[0] = count;
                } else if (std.mem.eql(u8, color, "green")) {
                    single_show[1] = count;
                } else if (std.mem.eql(u8, color, "blue")) {
                    single_show[2] = count;
                }
                std.debug.print(" {d} {s}", .{count, color});
                std.debug.print("\n", .{});

            }
            try my_shows.append(single_show);
        }
        try games.put(game_number, my_shows.items);
    }
    return games;
}

pub fn get_acceptable_games(
    allocator: Allocator, games: std.AutoHashMap(u32, [][3] u8)) ![]u32 {
    var acceptable_games: std.ArrayList(u32) = std.ArrayList(u32).init(allocator);
    var it = games.iterator();
    while (it.next()) |item| {
        var game_number: u32 = item.key_ptr.*;
        var shows = item.value_ptr.*;
        var ok = true;
        for (shows) |show| {
            var red = show[0];
            var green = show[1];
            var blue = show[2];
            if (red > 12 or green > 13 or blue > 14) {
                ok = false;
                break;
            }
        }
        if (ok) {
            try acceptable_games.append(game_number);
            std.debug.print("game: {d}\n", .{game_number});
        }
            
    }
    return acceptable_games.items;
}

pub fn get_min_per_game(
    allocator: Allocator, games: std.AutoHashMap(u32, [][3] u8)) ![][3]u8 {
    var min_per_game: std.ArrayList([3]u8) = std.ArrayList([3]u8).init(allocator);
    var it = games.iterator();
    while (it.next()) |item| {
        var mins = [3]u8 {0, 0, 0};
        var shows = item.value_ptr.*;
        for (shows) |show| {
            var red = show[0];
            var green = show[1];
            var blue = show[2];
            if (red > mins[0]) {
                mins[0] = red;
            }
            if (green > mins[1]) {
                mins[1] = green;
            }
            if (blue > mins[2]) {
                mins[2] = blue;
            }
        }
        try min_per_game.append(mins);
            
    }
    return min_per_game.items;
}

pub fn main() !void {
    var args = std.os.argv;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    if (args.len != 2) {
        std.debug.print("Usage: {s} <input_file>\n", .{args[0]});

        return;
    }
    const input_file: []const u8 = std.mem.span(args[1]);
    var games = try parse_file(allocator, input_file);
    var acceptable_games = try get_acceptable_games(allocator,  games);
    var sum_acceptable_games: u32 = 0;
    for (acceptable_games) |game| {
        sum_acceptable_games += game;
    }
    std.debug.print("sum: {d}\n", .{sum_acceptable_games});
    var min_per_game = try get_min_per_game(allocator, games);
    var power: u64 = 0;
    for (min_per_game) |min| {
        std.debug.print("min: {d} {d} {d}\n", .{min[0], min[1], min[2]});
        var red: u32 = min[0];
        var green: u32 = min[1];
        var blue: u32= min[2];
        power += red * green * blue;
    }
    std.debug.print("power: {d}\n", .{power});
}
