module simpleconfig.file;

import simpleconfig.attributes;

private string currentProcessBinary ()
{
    import std.process : thisProcessID;

    version (Windows)
    {
        import core.sys.windows.psapi : GetProcessImageFileName;
        char[1024] buffer;
        auto ln = GetProcessImageFileName(thisProcessID(), buffer.ptr, buffer.length);
        auto exec = buffer[0 .. ln];
    }
    else version (Posix)
    {
        import std.file : readLink;
        import std.format;
        auto exec = readLink(format("/proc/%s/exe", thisProcessID()));
    }

    return exec;
}

public void readConfiguration (S) (ref S dst)
{
    static assert (is(S == struct), "Only structs are supported as configuration target");

    import std.process : environment;
    import std.exception : ifThrown;
    import std.path : dirName;

    auto executable = currentProcessBinary();

    string[] locations = [
        ".",
        dirName(executable)
    ];

    version (Windows)
        locations ~= environment["LOCALAPPDATA%"];
    else version (Posix)
        locations ~= environment["XDG_CONFIG_HOME"].ifThrown("~/.config");

    foreach (location; locations)
    {
        import std.path : buildPath, baseName;
        import std.file : exists, readText;

        auto filename = buildPath(location, baseName(executable, ".exe") ~ ".cfg");
        if (exists(filename))
        {
            auto content = readText(filename);
            readConfigurationImpl(dst, content);
            return;
        }
    }
}

private template resolveName (alias Field)
{
    import std.traits;

    enum resolveName = getUDAs!(Field, CFG)[0].key.length
        ? getUDAs!(Field, CFG)[0].key
        : __traits(identifier, Field);
}

private string[2] extractKV (string line)
{
    import std.algorithm : findSplit;
    import std.string : strip;

    auto separated = line.findSplit("=");
    string key = strip(separated[0]);
    string value = strip(separated[2]);
    if (value[0] == '"' && value[$-1] == '"')
        value = value[1 .. $ -1];

    return [ key, value ];
}

unittest
{
    assert(extractKV(" key = value ") == [ "key", "value" ]);
    assert(extractKV(" key = \"value value\"") == [ "key", "value value" ]);
}

private void readConfigurationImpl (S) (ref S dst, string src)
{    
    import std.traits;
    import std.algorithm;
    import std.range;
    import std.conv;

    rt: foreach (line; src.splitter("\n"))
    {
        if (line.length == 0)
            continue;

        auto kv = extractKV(line);
        bool assign = false;

        static foreach (Field; getSymbolsByUDA!(S, CFG))
        {            
            if (kv[0] == resolveName!Field)                
            {
                auto pfield = &__traits(getMember, dst, __traits(identifier, Field));
                *pfield = to!(typeof(*pfield))(kv[1]);
                continue rt;
            }
        }
    }
}

unittest
{
    struct Config
    {
        @cfg
        string field1;
        @cfg("alias")
        int field2;
        @cfg("with space")
        string field3;
        string field4;
    }

    Config config;

    readConfigurationImpl(config, `
field1 = value1
alias = 42
with space = value3
field4 = ignored`
    );

    assert(config.field1 == "value1");
    assert(config.field2 == 42);
    assert(config.field3 == "value3");
    assert(config.field4 == "");
}