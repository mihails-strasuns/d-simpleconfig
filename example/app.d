import simpleconfig;

struct Config
{
    @cli
    string one;
    @cli @cfg("key")
    int two;
    @cfg("another key")
    string three;
}

void main ()
{
    Config config;
    readConfiguration(config);
    
    import std.stdio;
    writeln(config);
}