Library primarily intended to help quickly write small command-line tools.
Parses command-line arguments and configuration file and stores result into
provided D struct instance.

### Example

```D
void main ()
{
    import simpleconfig;

    struct Config
    {
        @cli
        int value;
        @cli("flag|f") @cfg("flag")
        string anothervalue;
        @cfg("some ratio")
        double ratio;

        void finalizeConfig ()
        {

        }
    }

    Config config;
    readConfiguration(config);
}
```

This snippet will do the following:

- Check standard locations for the current platform for the config file named
  `appname.cfg`. If found, parse it and initialize `config.anothervalue` from
  `flag` entry and `config.ration` from `some ratio` entry.
- Iterate through command-line arguments. If `--value` argument is found, it
  will be written to `config.value` (using `std.conv.to` for conversion). If
  either `--flag` or `-f` arguments are found, it will be written to
  `config.anothervalue`.
- Call `config.finalizeConfig` if defined for a given struct.

If value is set both by config file and command-line argument, the latter takes
priority.

### Config files

Currently config file is named `appname.cfg` and uses simple key-value format:

```
key = value
another key = " value that starts with a whitespace"
```

The following locations are checked for config file presence:

1) Current working directory
2) Same folder as the executable
3) `$XDG_CONFIG_HOME` (Posix) or `%LOCALAPPDATA%` (Windows)
