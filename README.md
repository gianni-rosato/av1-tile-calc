# AV1 Tile Calculator

CLI tool written in Zig that calculates the optimal tile dimensions for encoding video using the AV1 codec. It takes four command-line arguments:

* width: the input width in pixels
* height: the input height in pixels
* fps: the input frames per second
* bitrate_range: the desired bitrate range (accepts values 1, 2, or 3, corresponding to lowest, low, medium/high)

The tool calculates the number of tiles required to achieve the desired bitrate range, and outputs the following information:

* Tile Columns: the number of columns required to achieve the desired bitrate range, in both log-2 and literal formats.
* Tile Rows: the number of rows required to achieve the desired bitrate range, in both log-2 and literal formats.
* X-splits: the optimal Av1an x-splits value based on FPS. *useful for Av1an*
* Lag in Frames: the optimal lag in frames value based on the desired bitrate range. *useful for popular aomenc forks*

The output is generally useful for aomenc, SVT-AV1, libaom-av1 via FFmpeg, and rav1e, with some differences between how they may be used for each encoder. See the Help menu of the AV1 Tile Calculator for more info.

```bash
$ av1-tile-calc -h
AV1 Tile Calculator | inspired by autocompressor.net/tools/av1-calculator
Usage: av1-tile-calc [width] [height] [fps] [bitrate_range]

Options:
	Width:		Your input width in pixels
	Height:		Your input height in pixels
	fps:		Your input frames per second
	Bitrate Range:	Accepts either lowest (1), low (2), medium/high (3)

Output:
	Log-2:		Useful for aomenc & SVT-AV1
	Literal:	Useful for libaom-av1 & rav1e
	X-split length:	The -x (--extra-splits) option in Av1an
	Lag in Frames:	Useful for aom-av1-lavish & other forks
```

## Usage

To use the tool, simply run the executable with the four command-line arguments:
```bash
$ av1-tile-calc [width] [height] [fps] [bitrate_range]
```
For example:
```bash
$ av1-tile-calc 1920 1080 24 3
Bitrate Range: Medium/High
Tile Columns:
	Log-2:   0
	Literal: 1
Tile Rows:
	Log-2:   0
	Literal: 1
X-splits:	 240
Lag in Frames:	 48
```
This would calculate the tile dimensions for a 1920x1080 video at 24 fps, with a bitrate range of 3 (medium/high).

## Compilation

To build the tool, you will need to have the Zig programming language installed.

1. Run the following command to build the executable:
```
zig build
```

2. Locate the executable, which will be found in `zig-out/bin/` and will be called `av1-tile-calc`

The executable file called `av1-tile-calc` can then be run on your system.

## License & Contributions

The AV1 Tile Calculator was developed by Gianni Rosato and is licensed under the MIT License. See the included LICENSE file for more information.

Special thank you to RootAtKali of Auto-Rez Media Technologies, LLC for the inspiration from their [AV1 Encoding Calculator](https://autocompressor.net/tools/av1-calculator) web tool.