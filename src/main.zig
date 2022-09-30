const std = @import("std");

// Context object
// init
// update
// finish

// SHA3-256
// d = 256
// r = 1088  // 136 bytes
// c = 512

// c = b - r
// 512 = b - 1088
// b = 1600  // 200 bytes

const bytesPerBlock = 136;
const bytesPerState = 200;

const Block = struct {
    value: [bytesPerBlock]u8, // width r
};

fn pad(_: []const u8) []const Block {
    // compute the number of blocks

    // var blocks = std.mem.alignBackward(u64, data) / 8;
    // var padded = std.mem.alloc(Block, blocks + 1) catch unreachable;
    // std.mem.copy(u8, padded[0..data.len], data);
    // padded[data.len] = 0x80;
    // return padded;
}

const InputManager = struct {
    pending: []u8,

    pub fn init() InputManager {
        return InputManager{
            .pending = &[_]u8{},
        };
    }

    pub fn addData(_: *InputManager, _: []const u8) void {
        // TODO
    }

    pub fn getNextBlock(_: *InputManager) ?Block {
        return null;
    }
};

const Hasher = struct {
    state: [bytesPerState]u8, // width b
    input: InputManager,

    pub fn init() Hasher {
        return Hasher{
            .state = [_]u8{0} ** bytesPerState,
            .input = InputManager.init(),
        };
    }

    // pad
    // permute

    fn processBlock(_: *Hasher, _: Block) void {
        // xor
        // permute
    }

    pub fn add(self: *Hasher, data: []const u8) void {
        self.input.addData(data);
        while (self.input.getNextBlock()) |block| {
            self.processBlock(block);
        }
    }

    // TODO: gn finish(self: Hasher) []u8 { }
};

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    var hasher = Hasher.init();
    hasher.add("Hello, world!");
    // const hash = hasher.finish();

    // std.log.info("The hash was {}.", .{hash[0]});

    // Given an input bit string N, a padding function pad, a permutation
    // function f that operates on bit blocks of width b, a rate r and an output
    // length d, we have capacity c=b-r and the sponge construction
    // Z=sponge[f,pad,r](N,d), yielding a bit string Z of length d, works as
    // follows:

    // pad the input N using the pad function, yielding a padded bit string P
    // with a length divisible by r (such that n=len(P)/r is an integer)

    // break P into n consecutive r-bit pieces P0, ..., Pn−1

    // initialize the state S to a string of b zero bits

    // absorb the input into the state: for each block Pi:
    // extend Pi at the end by a string of c zero bits, yielding one of length b
    // XOR that with S
    // apply the block permutation f to the result, yielding a new state S
    // initialize Z to be the empty string
    // while the length of Z is less than d:
    // append the first r bits of S to Z
    // if Z is still less than d bits long, apply f to S, yielding a new state S
    // truncate Z to d bits

}

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
