module simpleconfig;

public import simpleconfig.attributes;

/**
    Reads a configuration data from a config file and
    command-line arguments.

    Command-line arguments will override config file entries.
    Config file will override defaults. Only fields marked with
    @cli and/or @cfg UDA will be updated, any other symbols will be ignored.

    Configuration file location will be checked in this order:
        - current working directory
        - same folder as the binary
        - $XDG_CONFIG_HOME/appname.cfg (Posix) or %LOCALAPPDATA%/appname.cfg (Windows)

    Params:
        dst = struct instance which will store configuration data
            and defines how it should be read
*/
void readConfiguration (S) (ref S dst)
{
    static assert (is(S == struct), "Only structs are supported as configuration target");
    
    static import simpleconfig.file;
    simpleconfig.file.readConfiguration(dst);

    static import simpleconfig.args;
    simpleconfig.args.readConfiguration(dst);

    static if (is(typeof(S.finalizeConfig())))
        dst.finalizeConfig();
}

///
unittest
{
    void example ()
    {
        struct S
        {
            @cli
            int value;
            @cli("flag|f") @cfg("flag")
            string anothervalue;

            void finalizeConfig () { }
        }

        S s;
        readConfiguration(s);
    }
}