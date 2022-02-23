import std.stdio;
import std.file;
import std.format;
import commandr;

import targets.dustermap;

int main(string[] args) {
	auto a = new Program("retiler", "0.1").summary("tiled map compiler")
		.author("redthing1")
		.add(new Argument("input", "path to tiled map file (.json)"))
		.add(new Argument("output", "path to output compiled map (.bin)"))
		.parse(args);

	auto in_file = a.arg("input");
	auto ou_file = a.arg("output");

	auto input_map_data = cast(ubyte[]) std.file.read(in_file);
	DusterMap parsed_map = parse_map_file(input_map_data);
	ubyte[] binmap = compile_duster_map(parsed_map);

	std.file.write(ou_file, binmap);

	return 0;
}
