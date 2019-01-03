module simpleconfig.args;

import simpleconfig.attributes;

/// See `simpleconfig.readConfiguration`
public string[] readConfiguration (S) (ref S dst)
{
    static assert (is(S == struct), "Only structs are supported as configuration target");

    import core.runtime;    
    return readConfigurationImpl(dst, Runtime.args());
}

private template resolveName (alias Field)
{
    import std.traits;

    enum resolveName = getUDAs!(Field, CLI)[0].full.length
        ? getUDAs!(Field, CLI)[0]
        : CLI(__traits(identifier, Field));
}

unittest
{
    struct S
    {
        @cli
        string field1;
        @cli("renamed|r")
        string field2;
    }

    static assert (resolveName!(S.field1).full == "field1");
    static assert (resolveName!(S.field1).single == dchar.init);
    static assert (resolveName!(S.field2).full == "renamed");
    static assert (resolveName!(S.field2).single == 'r');
}

private string[] readConfigurationImpl (S) (ref S dst, string[] src)
{
    import std.traits;
    import std.algorithm;
    import std.range.primitives;
    import std.conv;

    string[] remaining_args;
    bool assign = false;

    rt: foreach (idx, arg; src)
    {
        if (assign)
        {
            // skip argument of already processed flag
            assign = false;
            continue;
        }

        static foreach (Field; getSymbolsByUDA!(S, CLI))
        {
            if (arg.startsWith("--"))
                assign = resolveName!Field.full == arg[2 .. $];
            else if (arg.startsWith("-"))
                assign = resolveName!Field.single == arg[1 .. $].front;

            if (assign)
            {
                auto pfield = &__traits(getMember, dst, __traits(identifier, Field));
                *pfield = to!(typeof(*pfield))(src[idx + 1]);
                continue rt;
            }
        }

        remaining_args ~= arg;
    }

    return remaining_args;
}

unittest
{
    struct Config
    {
        @cli
        string field1;
        @cli("alias")
        int field2;
        @cli("long|l")
        string field3;
        string field4;
    }

    Config config;

    auto remaining = readConfigurationImpl(config, [
        "--field1", "value1",
        "--alias", "42",
        "-l", "value3",
        "--field4", "ignored"
    ]);

    assert(config.field1 == "value1");
    assert(config.field2 == 42);
    assert(config.field3 == "value3");
    assert(config.field4 == "");

    assert(remaining == [ "--field4", "ignored" ]);
}
