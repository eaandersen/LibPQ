/******************
   UNFINISHED!!!
******************/

/**
LibPQ:
    Access all components of the library as a record.
**/

let
    /* Temporary sample inputs */
    File = "C:\Users\Виталий\Desktop\LibPQ\Functions\fnReadParameters.m",
    Url = "https://raw.githubusercontent.com/tycho01/pquery/master/Load.pq",

    /* Load text content from local file or from web */
    Text.Load = (destination as text, optional local as logical) =>
        let
            Local = if local is null then true else local,
            Fetcher = if Local then File.Contents else Web.Contents
        in
            Text.FromBinary(
                Binary.Buffer(
                    Fetcher(destination)
                )
            ),

    /* Load Power Query function or module from file */
    Function.FromPath = (path as text, optional local as logical) =>
        Expression.Evaluate(Text.Load(path, local), #shared),

    /* Calculate where the function code is located */
    Function.GetPath = (funcname as text, directory as text, optional local as logical) =>
        let
            /* Defaults */
            Extension = ".m",
            Local = if local is null then true else local,
            PathSep = if Local then "\" else "/",  // Windows specific

            /* Path building */
            ProperDir = if Text.EndsWith(directory, PathSep)
                        then directory
                        else directory & PathSep,
            ProperName = Text.Replace(funcname, "_", "."),
            Return = ProperDir & ProperName & Extension
        in
            Return,

    /* Last touch: export helper functions defined above */
    Helpers = [
        Text.Load = Text.Load,
        Function.FromPath = Function.FromPath,
        Function.GetPath = Function.GetPath
    ],
    Library = "A record with all loaded functions", // TODO
    Return = Record.Combine({Helpers, Library})
in
    Function.FromPath(Url, false)
