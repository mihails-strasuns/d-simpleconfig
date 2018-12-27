/**
    Defines UDAs to be used with configuration structs.
*/
module simpleconfig.attributes;

// In this module @property is used for a UDA function to use return type
// as an attribute, not the function itself.

/// Marks field to be read from command-line arguments
public CLI cli (string description = "") @property
{
    import std.array : split;
    import std.range.primitives;

    string[] pair = split(description, '|');

    switch (pair.length)
    {
        case 0: return CLI();
        case 1: return CLI(pair[0], dchar.init);
        case 2: return CLI(pair[0], pair[1].front);
        default: assert(false);
    }
}

/// Marks field to be read from a configuration file
public CFG cfg (string key = "") @property
{
    return CFG(key);
}

package struct CFG
{
    string key;
}

package struct CLI
{
    string full;
    dchar  single;
}
