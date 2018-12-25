module simpleconfig.attributes;

// In this module @property is used for a UDA function to use return type
// as an attribute, not the function itself.

package struct CLI
{
    string full;
    dchar  single;
}

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

package struct CFG
{
    string key;
}

public CFG cfg (string key = "") @property
{
    return CFG(key);
}