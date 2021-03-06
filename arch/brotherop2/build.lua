include "third_party/ld80/build.lua"
include "third_party/zmac/build.lua"
include "utils/build.lua"

normalrule {
    name = "font_inc",
    ins = {
        "arch/brotherop2/utils+fontconvert",
        "utils+6x7font",
    },
    outleaves = { "font.inc" },
    commands = {
        "%{ins} > %{outs}"
    }
}

zmac {
    name = "boot_o",
    srcs = { "./boot.z80" },
    deps = {
        "include/*.lib",
        "./include/*.lib",
		"arch/common/utils/tty.lib",
		"+font_inc"
    },
}

ld80 {
    name = "boot",
	address = 0x5000,
    srcs = {
		"-P5000",
		"+boot_o"
    }
}

for _, n in pairs({"bios", "floppy", "tty"}) do
	zmac {
		name = n,
		srcs = { "./"..n..".z80" },
		deps = {
			"include/*.lib",
			"./include/*.lib",
			"arch/common/utils/tty.lib",
		},
	}
end

-- This is the bit which CP/M reloads on warm boot (well, some of it).
ld80 {
	name = "cpmfile",
	address = 0x9300,
	srcs = {
		"-P9300", "third_party/zcpr1+zcpr",
		"-P9b00", "third_party/zsdos+zsdos",
		"-Pa900",
		"+bios",
		"+floppy",
		"+tty",
	}
}

-- Produces the FAT bit of the disk image.
zmac {
	name = "fat",
	srcs = { "./fat.z80" },
	deps = {
		"+boot",
		"+cpmfile"
	}
}

ld80 {
	name = "bootfile",
	srcs = { "+fat" }
}

unix2cpm {
    name = "readme",
    srcs = { "README.md" }
}

diskimage {
	name = "diskimage",
	format = "brother-op2",
	bootfile = { "+bootfile" },
	map = {
		["dump.com"] = "cpmtools+dump",
		["stat.com"] = "cpmtools+stat",
		["asm.com"] = "cpmtools+asm",
		["copy.com"] = "cpmtools+copy",
		["submit.com"] = "cpmtools+submit",
		["bbcbasic.com"] = "third_party/bbcbasic+bbcbasic_ADM3A",
		["qe.com"] = "cpmtools+qe_BROTHEROP2",
		["mkfs.com"] = "cpmtools+mkfs",
		["rawdisk.com"] = "cpmtools+rawdisk",
        ["-readme.txt"] = "+readme",
	},
}

