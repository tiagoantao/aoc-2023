const std = @import("std");
const Allocator = std.mem.Allocator;


pub fn get_int_list(allocator: Allocator, string: []const u8) ![]u64 {
    var list: std.ArrayList(u64) = std.ArrayList(u64).init(allocator);
    var toks = std.mem.split(u8, string, " ");
    while (toks.next()) |tok| {
        if (std.mem.eql(u8, tok, "")) {
            continue;
        }
        var num: u64 = try std.fmt.parseInt(u64, tok, 10);
        try list.append(num);
    }
    return list.items;
}


const Almanac = struct {
    seeds: []u64,
    maps: [][][3]u64,
};

pub fn get_almanac(allocator: Allocator, file_name: []const u8) !Almanac {
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();
    var buf: [1024]u8 = undefined;

    var seeds: ?[]u64 = null;
    var in_map = false;
    var my_maps = std.ArrayList([][3]u64).init(allocator);
    var current_map = std.ArrayList([3]u64).init(allocator);
    while(try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (seeds) |_| { // ugly
        }
        else {
            var seed_split = std.mem.split(u8, line, ":");
            _ = seed_split.next();
            seeds = try get_int_list(allocator, seed_split.next().?);
            continue;
        }
        if (line.len == 0) {
            if (in_map) {
                try my_maps.append(current_map.items);
                in_map = false;
            }
            continue;
        }
        std.debug.print("line: {s}\n", .{line});
        if (line[line.len - 1] == ':') {
            current_map = std.ArrayList([3]u64).init(allocator);
            in_map = true;
            continue;
        }
        if (in_map) {
            var numbers = try get_int_list(allocator, line);
            var numbers3: [3]u64 = undefined;
            std.mem.copy(u64, &numbers3, numbers[0..3]);
            try current_map.append(numbers3);
        }
    }
    try my_maps.append(current_map.items);
    var almanac: Almanac = .{ .seeds = seeds.?, .maps = my_maps.items };

    return almanac;
}

pub fn get_location(map: [][3]u64, seed: u64) u64 {
    var location: ?u64 = null;
    for (map) |row| {
        var destination = row[0];
        var source = row[1];
        var range = row[2];
        if (seed >= source and seed < source + range) {
            //std.debug.print("found it! {d} {d}\n", .{seed, source});
            location = destination + seed - source;
            break;
        }
            
    }
    return location orelse seed;
}

pub fn get_locations(maps: [][][3]u64, seed: u64) u64 {
    var curr_value = seed;
    for (maps) |map| {
        curr_value = get_location(map, curr_value);
        //std.debug.print("curr_value: {d}\n", .{curr_value});
    }
    return curr_value;
}


pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    var args = std.os.argv;
    if (args.len != 2) {
        std.debug.print("usage: {s} <file>\n", .{args[0]});
        return;
    }
    const file_name = std.mem.span(args[1]);
    var almanac = try get_almanac(allocator, file_name);
    std.debug.print("seeds: {any}\n", .{almanac.seeds});
    for (almanac.maps) |map| {
        std.debug.print("map: {any}\n", .{map});
    }
    var smallest_location: u64 = std.math.maxInt(u64);
    for (almanac.seeds) |seed| {
        var loc = get_locations(almanac.maps, seed);
        std.debug.print("seed: {d} location: {d}\n", .{seed, loc});
        if (loc < smallest_location) {
            smallest_location = loc;
        }
    }
    std.debug.print("smallest location: {d}\n", .{smallest_location});

    var smallest_span_location: u64 = std.math.maxInt(u64);
    for (0..almanac.seeds.len/2) |i| {
        var start = almanac.seeds[2*i];
        var span = almanac.seeds[2*i+1];
        std.debug.print("start: {d} {d}\n", .{start, span});
        for (start..start+span) |seed| {
            var loc = get_locations(almanac.maps, seed);
            //std.debug.print("seed: {d} location: {d}\n", .{seed, loc});
            if (loc < smallest_span_location) {
                smallest_span_location = loc;
            }
        }
        std.debug.print("smallest span location: {d}\n", .{smallest_span_location});
    }
    std.debug.print("smallest span location: {d}\n", .{smallest_span_location});

}
