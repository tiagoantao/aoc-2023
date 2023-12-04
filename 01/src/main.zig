/// My very very first zig program
const std = @import("std");
const Allocator = std.mem.Allocator;


pub fn replace_number_strings(allocator: Allocator, orig: []const u8) ![]u8 {
    //2nd part of the puzzle
    var conv = std.StringHashMap([]const u8).init(allocator);
    defer conv.deinit();
    var replaced: [] u8 = try allocator.alloc(u8, orig.len);
    std.mem.copy(u8, replaced, orig);
    try conv.put("one", "1"); try conv.put("two", "2"); try conv.put("three", "3");
    try conv.put("four", "4"); try conv.put("five", "5"); try conv.put("six", "6");
    try conv.put("seven", "7"); try conv.put("eight", "8"); try conv.put("nine", "9");
    try conv.put("nine", "9");

    for (0..replaced.len) |i| {
        //std.debug.print("i: {d}\n", .{i});
        var it = conv.iterator();
        while (it.next()) |item| {
            var key = item.key_ptr.*;
            var value = item.value_ptr.*;
            if (replaced[i..].len >= key.len) {
                if (std.mem.eql(u8, replaced[i .. i+key.len], key)) {
                    //std.debug.print("Found {s}\n", .{key});
                    std.mem.copy(u8, replaced[i..], value);
                }
            }                    
        }
            
    }
    return replaced;
}

pub fn get_calibration(filename: []const u8) !void {
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var buf: [1024]u8 = undefined;
    var acum: u32 = 0;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var replaced_line = replace_number_strings(allocator, line) catch "";
        var first: u8 = 0;
        var last: u8 = 0;
        for (replaced_line) |c| {
            if (c >= '0' and c <= '9') {
                if (first == 0) {
                    first = c - '0';
                }
                last = c - '0';
            }
        }
        const my_val = first*10 + last;
        acum += my_val;
        std.debug.print("\n{s}\n{s}\n{d} {d}\n", .{line, replaced_line, my_val, acum});
        //std.debug.print("{d}\n", .{my_val});
    }
}


pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    var args = std.os.argv;
    if (args.len != 2) {
        try stdout.print("Usage: {s} [filename]\n", .{args[0]});
    }
    else {
        const filename = std.mem.span(args[1]);
        try get_calibration(filename);
    }

    try bw.flush();
}
