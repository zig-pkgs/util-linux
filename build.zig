const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const t = target.result;

    const upstream = b.dependency("upstream", .{});

    const config_h = b.addConfigHeader(.{
        .style = .blank,
    }, .{
        ._GNU_SOURCE = 1,
        .HAVE_ERR_H = 1,
        .HAVE_ERR = 1,
        .HAVE_ERRX = 1,
        .HAVE_WARN = 1,
        .HAVE_WARNX = 1,
        .HAVE_NANOSLEEP = 1,
        .HAVE_USLEEP = 1,
        .HAVE_REALLOCARRAY = 1,
        .HAVE_DIRFD = 1,
        .HAVE_OPENAT = 1,
        .HAVE_LOFF_T = 1,
        .HAVE_SYS_SYSMACROS_H = 1,
        .HAVE_SYS_STAT_H = 1,
        .HAVE_SYS_TYPES_H = 1,
        .HAVE_UNISTD_H = 1,
        .HAVE_STDLIB_H = 1,
        .HAVE_ERRNO_H = 1,
        .HAVE_GETOPT_H = 1,
        .HAVE_D_TYPE = 1,
        .HAVE_POSIX_FADVISE = 1,
        .HAVE_STRUCT_STAT_ST_MTIM_TV_NSEC = 1,
        .HAVE_PROGRAM_INVOCATION_SHORT_NAME = 1,
        .HAVE_LINUX_BLKZONED_H = 1,
        .HAVE_LINUX_CDROM_H = 1,
        .HAVE_LINUX_FD_H = 1,
        .HAVE_TLS = 1,
        .HAVE_GETAUXVAL = 1,
        .HAVE_FSYNC = 1,
        .HAVE_SYS_FILE_H = 1,
        .HAVE_SYS_IOCTL_H = 1,
        .HAVE_SYS_TTYDEFAULTS_H = 1,
        .HAVE_LINUX_OPENAT2_H = 1,
        .HAVE_GETDTABLESIZE = 1,

        ._PATH_SYSCONFDIR = "/etc",
        ._PATH_LOCALSTATEDIR = "/var",
    });

    const cflags = [_][]const u8{ "-includeconfig.h", "-std=c99" };

    const libcommon = b.addLibrary(.{
        .name = "common",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (t.os.tag == .linux) {
        libcommon.root_module.addCSourceFiles(.{
            .root = upstream.path("lib"),
            .files = &.{
                "linux_version.c",
                "loopdev.c",
                "pidfd-utils.c",
            },
            .flags = &cflags,
        });
    }
    libcommon.root_module.addIncludePath(upstream.path("include"));
    libcommon.root_module.addIncludePath(upstream.path("lib"));
    libcommon.root_module.addConfigHeader(config_h);
    libcommon.root_module.addCSourceFiles(.{
        .root = upstream.path("lib"),
        .files = &common_src,
        .flags = &cflags,
    });
    b.installArtifact(libcommon);

    const blkid_h = b.addConfigHeader(.{
        .style = .{ .autoconf_at = upstream.path("libblkid/src/blkid.h.in") },
        .include_path = "blkid.h",
    }, .{
        .LIBBLKID_VERSION = "1.1.0",
        .LIBBLKID_MAJOR_VERSION = 1,
        .LIBBLKID_MINOR_VERSION = 1,
        .LIBBLKID_PATCH_VERSION = 0,
        .LIBBLKID_DATE = "26-Feb-2026",
    });

    const libblkid = b.addLibrary(.{
        .name = "blkid",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (t.os.tag == .linux) {
        libblkid.root_module.addCSourceFiles(.{
            .root = upstream.path("libblkid"),
            .files = &.{
                "src/topology/dm.c",
                "src/topology/evms.c",
                "src/topology/ioctl.c",
                "src/topology/lvm.c",
                "src/topology/md.c",
                "src/topology/sysfs.c",
            },
            .flags = &cflags,
        });
    }
    libblkid.root_module.addIncludePath(upstream.path("include"));
    libblkid.root_module.addIncludePath(upstream.path("libblkid/src"));
    libblkid.root_module.addConfigHeader(blkid_h);
    libblkid.root_module.addConfigHeader(config_h);
    libblkid.root_module.addCSourceFiles(.{
        .root = upstream.path("libblkid"),
        .files = &blkid_src,

        .flags = &cflags,
    });
    libblkid.installConfigHeader(blkid_h);
    b.installArtifact(libblkid);

    const libuuid = b.addLibrary(.{
        .name = "uuid",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    libuuid.root_module.addIncludePath(upstream.path("include"));
    libuuid.root_module.addIncludePath(upstream.path("libuuid/src"));
    libuuid.root_module.addConfigHeader(config_h);
    libuuid.root_module.addCSourceFiles(.{
        .root = upstream.path("libuuid"),
        .files = &uuid_src,
        .flags = &cflags,
    });
    libuuid.installHeader(upstream.path("libuuid/src/uuid.h"), "uuid.h");
    b.installArtifact(libuuid);

    const fdisk_h = b.addConfigHeader(.{
        .style = .{ .autoconf_at = upstream.path("libfdisk/src/libfdisk.h.in") },
        .include_path = "libfdisk.h",
    }, .{
        .LIBFDISK_VERSION = "1.1.0",
        .LIBFDISK_MAJOR_VERSION = 1,
        .LIBFDISK_MINOR_VERSION = 1,
        .LIBFDISK_PATCH_VERSION = 0,
    });

    const libfdisk = b.addLibrary(.{
        .name = "fdisk",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    libfdisk.root_module.addConfigHeader(fdisk_h);
    libfdisk.root_module.linkLibrary(libblkid);
    libfdisk.root_module.linkLibrary(libuuid);
    libfdisk.root_module.linkLibrary(libcommon);
    libfdisk.root_module.addIncludePath(upstream.path("include"));
    libfdisk.root_module.addIncludePath(upstream.path("libfdisk/src"));
    libfdisk.root_module.addConfigHeader(config_h);
    libfdisk.root_module.addCSourceFiles(.{
        .root = upstream.path("libfdisk"),
        .files = &fdisk_src,
        .flags = &cflags,
    });
    libfdisk.installConfigHeader(fdisk_h);
    b.installArtifact(libfdisk);
}

const common_src = [_][]const u8{
    "blkdev.c",
    "buffer.c",
    "canonicalize.c",
    "color-names.c",
    "crc32.c",
    "crc32c.c",
    "crc64.c",
    "c_strtod.c",
    "debug.c",
    "default_shell.c",
    "encode.c",
    "env.c",
    "fileutils.c",
    "jsonwrt.c",
    "mangle.c",
    "match.c",
    "mbsalign.c",
    "mbsedit.c",
    "pidutils.c",
    "pwdutils.c",
    "sha256.c",
    "signames.c",
    "timeutils.c",
    "ttyutils.c",
    "xxhash.c",
    "configs.c",

    "idcache.c",
    "randutils.c",
    "md5.c",
    "sha1.c",
    "strutils.c",
    "strv.c",
    "pager.c",

    "path.c",
    "procfs.c",
    "sysfs.c",
};

const blkid_src = [_][]const u8{
    "src/init.c",
    "src/cache.c",
    "src/config.c",
    "src/dev.c",
    "src/devname.c",
    "src/devno.c",
    "src/encode.c",
    "src/evaluate.c",
    "src/getsize.c",
    "src/probe.c",
    "src/read.c",
    "src/resolve.c",
    "src/save.c",
    "src/tag.c",
    "src/verify.c",
    "src/version.c",

    "src/partitions/aix.c",
    "src/partitions/atari.c",
    "src/partitions/bsd.c",
    "src/partitions/dos.c",
    "src/partitions/gpt.c",
    "src/partitions/mac.c",
    "src/partitions/minix.c",
    "src/partitions/partitions.c",
    "src/partitions/sgi.c",
    "src/partitions/solaris_x86.c",
    "src/partitions/sun.c",
    "src/partitions/ultrix.c",
    "src/partitions/unixware.c",

    "src/superblocks/adaptec_raid.c",
    "src/superblocks/apfs.c",
    "src/superblocks/bcache.c",
    "src/superblocks/befs.c",
    "src/superblocks/bfs.c",
    "src/superblocks/bitlocker.c",
    "src/superblocks/bluestore.c",
    "src/superblocks/btrfs.c",
    "src/superblocks/cs_fvault2.c",
    "src/superblocks/cramfs.c",
    "src/superblocks/ddf_raid.c",
    "src/superblocks/drbd.c",
    "src/superblocks/drbdproxy_datalog.c",
    "src/superblocks/drbdmanage.c",
    "src/superblocks/exfat.c",
    "src/superblocks/exfs.c",
    "src/superblocks/ext.c",
    "src/superblocks/f2fs.c",
    "src/superblocks/gfs.c",
    "src/superblocks/hfs.c",
    "src/superblocks/highpoint_raid.c",
    "src/superblocks/hpfs.c",
    "src/superblocks/iso9660.c",
    "src/superblocks/isw_raid.c",
    "src/superblocks/jfs.c",
    "src/superblocks/jmicron_raid.c",
    "src/superblocks/linux_raid.c",
    "src/superblocks/lsi_raid.c",
    "src/superblocks/luks.c",
    "src/superblocks/lvm.c",
    "src/superblocks/minix.c",
    "src/superblocks/mpool.c",
    "src/superblocks/netware.c",
    "src/superblocks/nilfs.c",
    "src/superblocks/ntfs.c",
    "src/superblocks/refs.c",
    "src/superblocks/nvidia_raid.c",
    "src/superblocks/ocfs.c",
    "src/superblocks/promise_raid.c",
    "src/superblocks/reiserfs.c",
    "src/superblocks/romfs.c",
    "src/superblocks/scoutfs.c",
    "src/superblocks/silicon_raid.c",
    "src/superblocks/squashfs.c",
    "src/superblocks/stratis.c",
    "src/superblocks/superblocks.c",
    "src/superblocks/swap.c",
    "src/superblocks/sysv.c",
    "src/superblocks/ubi.c",
    "src/superblocks/ubifs.c",
    "src/superblocks/udf.c",
    "src/superblocks/ufs.c",
    "src/superblocks/vdo.c",
    "src/superblocks/vfat.c",
    "src/superblocks/via_raid.c",
    "src/superblocks/vmfs.c",
    "src/superblocks/vxfs.c",
    "src/superblocks/xfs.c",
    "src/superblocks/zfs.c",
    "src/superblocks/zonefs.c",
    "src/superblocks/erofs.c",

    "src/topology/topology.c",
};

const uuid_src = [_][]const u8{
    "src/clear.c",
    "src/compare.c",
    "src/copy.c",
    "src/gen_uuid.c",
    "src/isnull.c",
    "src/pack.c",
    "src/parse.c",
    "src/uuid_time.c",

    "src/predefined.c",
    "src/pack.c",
    "src/unpack.c",
    "src/unparse.c",
};

const fdisk_src = [_][]const u8{
    "src/init.c",
    "src/field.c",
    "src/item.c",
    "src/test.c",
    "src/ask.c",
    "src/alignment.c",
    "src/label.c",
    "src/utils.c",
    "src/context.c",
    "src/parttype.c",
    "src/partition.c",
    "src/table.c",
    "src/iter.c",
    "src/script.c",
    "src/version.c",
    "src/wipe.c",

    "src/sun.c",
    "src/sgi.c",
    "src/dos.c",
    "src/bsd.c",
    "src/gpt.c",
};
