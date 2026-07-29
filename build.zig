const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zioansi_mod = b.dependency("zioansi", .{
        .target = target,
        .optimize = optimize,
    }).module("zioansi");

    const mod = b.addModule("zioconsole", .{
        .root_source_file = b.path("src/zioconsole.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addImport("zioansi", zioansi_mod);

    const unit_tests = b.addTest(.{ .root_module = mod });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
