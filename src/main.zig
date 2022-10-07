const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

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

    pub fn init() Block {
        return Block{
            .value = [_]u8{0} ** bytesPerBlock,
        };
    }
};

fn pad(data: []const u8) Block {
    // Goal is to add two 1 bits and then enough 0 bits between then to make
    // an exact round of blocks.
    assert(data.len < bytesPerBlock);

    // 1000000001 is 0x81
    const lonePadByte = 0x81;
    const startPadByte = 0x80;
    const endPadByte = 0x01;

    var block = Block.init();
    std.mem.copy(u8, block.value[0..], data);

    if (data.len + 1 == bytesPerBlock) {
        block.value[data.len] = lonePadByte;
        return block;
    }

    block.value[data.len] = startPadByte;
    block.value[block.value.len - 1] = endPadByte;
    return block;
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "padding bytes" {
    // Zig has separate types for null terminated arrays vs slices
    // 'A' would be null-terminated array and the wrong type.
    const upperCaseA = [1]u8{0x65}; // ASCII 'A'
    try expectEqual(pad((upperCaseA ** (bytesPerBlock - 1))[0..]), Block{
        .value = upperCaseA ** (bytesPerBlock - 1) ++ [_]u8{0x81},
    });

    try expectEqual(pad((upperCaseA ** (bytesPerBlock - 2))[0..]), Block{
        .value = upperCaseA ** (bytesPerBlock - 2) ++ [_]u8{0x80} ++ [_]u8{0x01},
    });

    try expectEqual(pad((upperCaseA ** 4)[0..]), Block{
        .value = upperCaseA ** 4 ++ [_]u8{0x80} ++ [_]u8{0x00} ** (bytesPerBlock - 6) ++ [_]u8{0x01},
    });
}

const BlockMaker = struct {
    pending: ArrayList(u8),

    pub fn init(allocator: Allocator) BlockMaker {
        return BlockMaker{
            .pending = ArrayList(u8).init(allocator),
        };
    }

    pub fn addData(self: *BlockMaker, data: []const u8) void {
        self.pending.appendSlice(data);
    }

    pub fn getNextBlock(self: *BlockMaker) ?Block {
        if (self.pending.items.len < bytesPerBlock) {
            return null;
        }
        const block = Block{
            .value = self.pending.items[0..bytesPerBlock],
        };
        self.pending.replaceRange(0, bytesPerBlock, &[_]u8{});
        return block;
    }

    pub fn finish(self: *BlockMaker) Block {
        const block = pad(self.pending);
        self.pending.clearAndFree();
        return block;
    }
};

const Hasher = struct {
    state: [bytesPerState]u8, // width b
    maker: BlockMaker,
    isFinished: bool,

    pub fn init() Hasher {
        return Hasher{
            .state = [_]u8{0} ** bytesPerState,
            .maker = BlockMaker.init(),
            .isFinished = false,
        };
    }

    fn processBlock(self: *Hasher, block: Block) void {
        // Permute the bits of the block.
        // xor the block into the state.
        for (block.value) |byte, i| {
            self.state[i] ^= byte;
        }
    }

    pub fn add(self: *Hasher, data: []const u8) void {
        assert(!self.isFinished);
        self.maker.addData(data);
        while (self.maker.getNextBlock()) |block| {
            self.processBlock(block);
        }
    }

    pub fn finish(self: *Hasher) []u8 {
        assert(!self.isFinished);
        const block = self.maker.finish();
        self.processBlock(block);
        self.isFinished = true;
        return self.state[0..];
    }
};

test "xor hasher" {
    var hasher = Hasher.init();
    hasher.add("abc");
    hasher.add("def");
    try expect(std.mem.eql(u8, hasher.finish(), &[_]u8{ 0x3a, 0x98, 0x0d, 0x19, 0x9a, 0x7c, 0xe9, 0x30, 0x0a, 0x5d, 0x7e, 0x2d, 0x86, 0x55, 0xbd, 0x38, 0x60, 0xeb, 0xdb, 0x10, 0x7e, 0x9e, 0x11, 0x23, 0x0c, 0xc7, 0xbf, 0x63, 0xf6, 0xe1, 0xda, 0x27 }));
}

pub fn main() anyerror!void {
    std.log.info("All your codebase are belong to us.", .{});

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();

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
