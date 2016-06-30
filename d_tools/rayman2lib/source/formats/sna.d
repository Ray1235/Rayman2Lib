﻿module formats.sna;

import std.stdio, std.conv, std.algorithm, core.memory, consoled;
import std.file : read;
import decoder, utils, global;

struct SNAPart {
	ubyte id;
	uint size;
	uint position;
	ubyte* dataPointer;
}

class SNAFormat
{
	ubyte[] data;
	SNAPart[] parts;

	this(string filename)
	{
		this(cast(ubyte[])read(filename));
	}

	this(ubyte[] data)
	{
		writecln(Fg.lightMagenta, "Parsing SNA");
		this.data = decodeData(data);
		loadedSnas ~= this;
		parse();

		GC.removeRange(data.ptr);
	}

	private void parse() {
		auto reader = new MemoryReader(data);

		reader.read!uint; // Skip first 4 bytes

		do {
			SNAPart part;

			part.position = reader.position;

			part.id  = reader.read!ubyte;
			auto memorySomething = reader.read!ubyte;
			auto v32 = reader.read!ubyte;
			auto somethingRelatedToRelocation = reader.read!uint;

			if(somethingRelatedToRelocation != -1) {
				auto v42 = reader.read!uint;
				auto v27 = reader.read!uint;
				auto v33 = reader.read!uint;
				part.size = reader.read!uint;

				part.dataPointer = data.ptr + reader.position;

				if(gptPointerRelocation[10 * part.id + memorySomething] == 0)
					gptPointerRelocation[10 * part.id + memorySomething] = cast(uint)part.dataPointer - somethingRelatedToRelocation;

				writecln(Fg.lightGreen, "SNA Relocation ID: ", Fg.white, "0x", (10 * part.id + memorySomething).to!string(16), Fg.lightGreen, "\t\tPoints at ", Fg.white, "0x", reader.position.to!string(16));
				//writeln("Part data pointer: 0x", part.dataPointer);
				//writeln("somethingRelatedToRelocation: 0x", somethingRelatedToRelocation.to!string(16));
				//writeln([v42, v27, v33].map!"a.to!string(16)");

				parts ~= part;

				reader.position += part.size;
			}
			else {
				writeln("Empty SNA block");
			}
		}
		while(!reader.isEof);
	}

	void printInfo() {
		foreach(part; parts) {
			writeln("Part id: ", part.id, "\n\tSize: ", part.size);
		}
	}
}

