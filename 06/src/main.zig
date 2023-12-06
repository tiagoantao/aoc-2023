const std = @import("std");

const Play = struct {
    time: u32,
    distance: u64,
};

const ex1: [3] Play = [_]Play {
    Play { .time = 7, .distance = 9 },
    Play { .time = 15, .distance = 40 },
    Play { .time = 30, .distance = 200 },
};

const ex2: [4] Play = [_]Play {
    Play { .time = 42, .distance = 284 },
    Play { .time = 68, .distance = 1005 },
    Play { .time = 69, .distance = 1122 },
    Play { .time = 85, .distance = 1341 },
};

const ex3: [1] Play = [_]Play {
    Play { .time = 42686985, .distance = 284100511221341 },
};

pub fn compute_wins(plays: []Play) void {
    var multi: u64 = 1;
    for (plays) |play| {
        var wins: u64 = 0;
        for (0..play.time) |press_time| {
            var my_distance = press_time * (play.time - press_time);
            if (my_distance > play.distance) {
                wins += 1;
            }
        }
        std.debug.print("wins: {}\n", .{wins});
        multi *= wins;
            
    }
    std.debug.print("multi: {}\n", .{multi});
}

pub fn main() !void {
    var my_plays = ex2;
    compute_wins(&my_plays);
    var my_plays2 = ex3;
    compute_wins(&my_plays2);
}

