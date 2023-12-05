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

const Play = struct {
    card_id: u64,
    win: []u64,
    mine: []u64,
};

pub fn get_cards(allocator: Allocator, file_name: []const u8) ![]Play {
//pub fn get_cards(allocator: Allocator, file_name: []const u8) !void {
    var list: std.ArrayList(Play) = std.ArrayList(Play).init(allocator);
    var file = try std.fs.cwd().openFile(file_name, .{});
    defer file.close();
    var reader = std.io.bufferedReader(file.reader());
    var stream = reader.reader();
    var buf: [4096]u8 = undefined;
    while (try stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var card_top = std.mem.split(u8, line, ":");
        var card_number_toks = std.mem.split(u8, card_top.next().?, " ");
        _ = card_number_toks.next();
        while (true) {
            var card_tok = card_number_toks.next().?;
            if (std.mem.eql(u8, card_tok, "")) {
                continue;
            }
            var card_id: u64 = try std.fmt.parseInt(u64, card_tok, 10);
            //std.debug.print("card_id: {any}\n", .{card_id});
            var all_numbers = card_top.next().?;
            var win_mine = std.mem.split(u8, all_numbers, "|");
            //std.debug.print("all_numbers: {s}\n", .{all_numbers});
            var win = try get_int_list(allocator, win_mine.next().?);
            //std.debug.print("win: {any}\n", .{win});
            var mine = try get_int_list(allocator, win_mine.next().?);
            //std.debug.print("mine: {any}\n", .{mine});
            try list.append(Play{ .card_id = card_id, .win = win, .mine = mine });
            break;
        }
    }
    return list.items;
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
    //get_cards(allocator, file_name);
    const plays = try get_cards(allocator, file_name);


    // part 1 + 2
    var points: u64 = 0;
    var num_cards = std.AutoHashMap(u64, u64).init(allocator);
    var tot_cards: u64 = 0;
    for (plays) |play| {
        if (!num_cards.contains(play.card_id)) {
            try num_cards.put(play.card_id, 1);
        }
        else {
            try num_cards.put(play.card_id, num_cards.get(play.card_id).? + 1);
        }
        const my_cards = num_cards.get(play.card_id).?;
        var num_wins: u8 = 0;
        for (play.mine) |mine| {
            if (std.mem.indexOfScalar(u64, play.win, mine)) |_| {
                num_wins += 1;
            }
        }
        std.debug.print("\ncard_id: {any}\n", .{play.card_id});
        std.debug.print("win: {any}\n", .{play.win});
        std.debug.print("mine: {any}\n", .{play.mine});
        std.debug.print("num wins: {d}\n", .{num_wins});
        std.debug.print("num cards: {d}\n", .{my_cards});
        if (num_wins > 0) {
            points += std.math.pow(u64, 2, num_wins-1);
            for (1..num_wins+1) |i| {
                if (!num_cards.contains(play.card_id + i)) {
                    try num_cards.put(play.card_id + i, my_cards);
                    // Doesn't matter if we overflow
                }
                else {
                    try num_cards.put(play.card_id + i, num_cards.get(play.card_id + i).? + my_cards);
                }

            }
        }
        tot_cards += num_cards.get(play.card_id).?;
    }
    std.debug.print("points: {d}\n", .{points});
    std.debug.print("cards: {d}\n", .{tot_cards});
}
