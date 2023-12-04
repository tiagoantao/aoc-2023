const std = @import("std");
const Allocator = std.mem.Allocator;


pub fn get_schematic(allocator: Allocator, filename: []const u8) ![][]u8 {
    var schematic = std.ArrayList([]u8).init(allocator);
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();
    var buf: [4096]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const my_line = try allocator.alloc(u8, line.len);
        std.mem.copy(u8, my_line, line);
        try schematic.append(my_line);
    }
    return schematic.items;
}

const Location = struct {
    line: u32,
    start: u8,
    end: u8
};

pub fn get_number_locations(allocator: Allocator, schematic: [][]u8) ![]Location {
    var number_locations = std.ArrayList(Location).init(allocator);
    var line: u16 = 0;
    for (schematic) |row| {
        var start: u8 = 0;
        var in_number = false;
        var col: u8 = 0;
        std.debug.print("row: {s}\n", .{row});
        for (row) |c| {
            if (c >= '0' and c <= '9') {
                if (in_number) {
                    col += 1;
                    continue;
                }
                else {
                    in_number = true;
                    start = col;            
                }
            } else {
                if (in_number) {
                    //std.debug.print("line: {d} start: {d} end: {d}\n", .{line, start, col});
                    try number_locations.append(Location{.line=line, .start=start, .end=col});
                }
                in_number = false;
            }
            col += 1;
        }
        if (in_number) {
            try number_locations.append(Location{.line=line, .start=start, .end=col});
        }
        line += 1;
    }
    return number_locations.items;
}

pub fn get_number(schematic: [][]u8, location: Location) u32 {
    var line = schematic[location.line];
    var number_str = line[location.start..location.end];
    //std.debug.print("number_str: {s}\n", .{number_str});
    return std.fmt.parseUnsigned(u32, number_str, 10) catch 0;
}

pub fn is_part(schematic: [][]u8, location: Location) bool {
    var line_len = schematic[0].len;
    var start_x: usize = 0;
    if (location.start > 0) {
        start_x = location.start - 1;
    }
    var end_x = line_len;
    if (location.end < line_len) {
        end_x = location.end + 1;
    }
    //horizontal
    if (location.start > 0) {
        if (schematic[location.line][location.start-1] != '.') {
            return true;
        }
    }
    if (location.end < line_len) {
        if (schematic[location.line][location.end] != '.') {
            return true;
        }
    }
    //vertical
    if (location.line > 0) {
        for (start_x..end_x) |col| {
            if (schematic[location.line-1][col] != '.') {
                return true;
            }
        }
    }
    if (location.line < schematic.len - 1) {
        for (start_x..end_x) |col| {
            if (schematic[location.line+1][col] != '.') {
                return true;
            }
        }
    }
    return false;
}

pub fn find_gears(allocator: Allocator, schematic: [][]u8, location: Location) ![]Location {
    var gears = std.ArrayList(Location).init(allocator);
    var line_len : u8 = @truncate(schematic[0].len);
    var start_x: u8 = 0;
    if (location.start > 0) {
        start_x = location.start - 1;
    }
    var end_x: u8 = line_len;
    if (location.end < line_len) {
        end_x = location.end + 1;
    }
    //horizontal
    if (location.start > 0) {
        if (schematic[location.line][location.start-1] == '*') {
            try gears.append(Location{.line=location.line, .start=location.start-1, .end=location.start-1});
                    
        }
    }
    if (location.end < line_len) {
        if (schematic[location.line][location.end] == '*') {
            try gears.append(Location{.line=location.line, .start=location.end, .end=location.end});
        }
    }
    //vertical
    if (location.line > 0) {
        for (start_x..end_x) |col| {
            if (schematic[location.line-1][col] == '*') {
                var my_col: u8 = @truncate(col);
                try gears.append(Location{.line=location.line-1, .start=my_col, .end=my_col});
            }
        }
    }
    if (location.line < schematic.len - 1) {
        for (start_x..end_x) |col| {
            if (schematic[location.line+1][col] == '*') {
                var my_col: u8 = @truncate(col);
                try gears.append(Location{.line=location.line+1, .start=my_col, .end=my_col});
            }
        }
    }
    return gears.items;
}


pub fn main() !void {
    var args = std.os.argv;
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();
    if (args.len != 2) {
        std.debug.print("Usage: {s} <filename>\n", .{args[0]});
        return;
    }
    var filename = std.mem.span(args[1]);
    var schematic = try get_schematic(allocator, filename);
    var locations = try get_number_locations(allocator, schematic);
    var acum: u32 = 0;
    var all_gears = std.AutoHashMap(Location, std.ArrayList(u32)).init(allocator);
    for (locations) |location| {
        var number = get_number(schematic, location);
        if (is_part(schematic, location)) {
            std.debug.print("location: {d} {d} {d}\n", .{location.line, location.start, location.end});
            std.debug.print("number: {d}\n", .{number});
            var gears = try find_gears(allocator, schematic, location);
            for (gears) |gear| {
                if (all_gears.contains(gear)) {
                    var my_list = all_gears.get(gear).?;
                    try my_list.append(number);
                    try all_gears.put(gear, my_list);
                }
                else {
                    var my_list = std.ArrayList(u32).init(allocator);
                    try my_list.append(number);
                    try all_gears.put(gear, my_list);
                }
            }
            acum += number;
                    
        }
        else {
            std.debug.print("NOT: {d}\n", .{number});
        }
        
    }
    var it = all_gears.iterator();
    var all_gear_acum: u32 = 0;
    while (it.next()) |gear| {
        var list = gear.value_ptr.*.items;
        if (list.len > 1) {
            var gear_acum: u32 = 1;
            for (list) |number| {
                gear_acum *= number;
            }
            all_gear_acum += gear_acum;
        }
    }
    std.debug.print("acum: {d}\n", .{acum});
    std.debug.print("gear acum: {d}\n", .{all_gear_acum});

}
