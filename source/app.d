import std.stdio;
import std.file;
import std.format;
import commandr;

import mapload;

import targets.base;
import targets.dummy;
import targets.dustermap;

int main(string[] args) {
	auto a = new Program("retiler", "0.1").summary("tiled map compiler")
		.author("redthing1")
		.add(new Flag("v", null, "turns on more verbose output").name("verbose"))
		.add(new Argument("input", "path to tiled map file (.json)"))
		.add(new Argument("output", "path to output compiled map (.bin)"))
		.add(new Option("t", "target", "map compile target format")
				.defaultValue("dummy"))
		.parse(args);

	MapCompileTarget[string] targets_table = [
		"dummy": new DummyMapTarget(),
		"duster": new DusterMapTarget(),
	];

	auto in_file = a.arg("input");
	auto ou_file = a.arg("output");
	auto verbose = a.flag("verbose");
	auto selected_target = a.option("target");

	// read input file
	if (verbose)
		writefln("reading input file");
	auto input_map_data = cast(ubyte[]) std.file.read(in_file);

	if (selected_target !in targets_table) {
		writefln("unknown target: ", selected_target);
		return 1;
	}

	// create target
	auto target = targets_table[selected_target];
	target.verbose = verbose;
	if (verbose)
		writefln("using map compile target %s (%s)", target.name, target.description);

	// load map with target
	if (verbose)
		writefln("running target[%s] map loader", target.name);
	target.load_map(input_map_data);

	auto tool_load = TiledMap.load(input_map_data);
	writefln("loaded map: %s", tool_load);

	// compile map with target
	if (verbose)
		writefln("compiling map with target[%s]", target.name);
	ubyte[] output_bin = target.compile_map();

	// show stats on output file
	if (verbose)
		writefln("  output: %s (%d bytes)", ou_file, output_bin.length);

	std.file.write(ou_file, output_bin);

	return 0;
}
