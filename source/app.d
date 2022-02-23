import std.stdio;
import std.file;
import std.format;
import commandr;

import targets.dustermap;

int main(string[] args) {
	auto a = new Program("retiler", "0.1").summary("tiled map compiler")
		.author("redthing1")
		.add(new Flag("v", null, "turns on more verbose output").name("verbose"))
		.add(new Argument("input", "path to tiled map file (.json)"))
		.add(new Argument("output", "path to output compiled map (.bin)"))
		.parse(args);

	auto in_file = a.arg("input");
	auto ou_file = a.arg("output");
	auto verbose = a.flag("verbose");

	// read input file
	if (verbose)
		writefln("reading input file");
	auto input_map_data = cast(ubyte[]) std.file.read(in_file);

	// create target
	auto target = new DusterMapTarget();
	target.verbose = verbose;
	if (verbose)
		writefln("using map compile target %s (%s)", target.name, target.description);

	// load map with target
	if (verbose)
		writefln("running target map loader");
	target.load_map(input_map_data);

	// compile map with target
	if (verbose)
		writefln("compiling map with target");
	ubyte[] output_bin = target.compile_map();

	std.file.write(ou_file, output_bin);

	return 0;
}
