module simpleconfig.args;

import simpleconfig.attributes;

public void readConfiguration (S) (ref S dst)
{
    static assert (is(S == struct), "Only structs are supported as configuration target");
    
    import core.runtime;

    readConfigurationImpl(dst, Runtime.args());
}

private template resolveName (alias Field)
{
    import std.traits;

    enum resolveName = getUDAs!(Field, CLI)[0].full.length
        ? getUDAs!(Field, CLI)[0]
        : CLI(__traits(identifier, Field));
}

private void readConfigurationImpl (S) (ref S dst, string[] src)
{    
    import std.traits;
    import std.algorithm;
    import std.range.primitives;
    import std.conv;

    rt: foreach (idx, arg; src)
    {
        bool assign = false;

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
    }
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

    readConfigurationImpl(config, [
        "--field1", "value1",
        "--alias", "42",
        "-l", "value3",
        "--field4", "ignored"
    ]);

    assert(config.field1 == "value1");
    assert(config.field2 == 42);
    assert(config.field3 == "value3");
    assert(config.field4 == "");
}