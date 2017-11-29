/******************
   UNFINISHED!!!
******************/

/**
LibPQ:
    Access all components of the library as a record.
**/

let
    /* Constants */
    EXTENSION = ".m",
    PATHSEPLOCAL = Text.Start("\\",1),
    PATHSEPREMOTE = "/",

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
    Module.FromPath = (path as text, optional local as logical) =>
        Expression.Evaluate(Text.Load(path, local), #shared),

    /* Calculate where the function code is located */
    Module.BuildPath = (funcname as text, directory as text, optional local as logical) =>
        let
            /* Defaults */
            Local = if local is null then true else local,
            PathSep = if Local then PATHSEPLOCAL else PATHSEPREMOTE,

            /* Path building */
            ProperDir = if Text.EndsWith(directory, PathSep)
                        then directory
                        else directory & PathSep,
            ProperName = Text.Replace(funcname, "_", "."),
            Return = ProperDir & ProperName & EXTENSION
        in
            Return,

    /* Find all modules in the list of directories */
    Module.Explore = (directories as list) =>
        let
            Files = List.Generate(
                () => [i = -1, results = 0],
                each [i] < List.Count(directories),
                each [
                    i = [i]+1,
                    folder = directories{i},
                    files = Folder.Contents(folder),
                    filter = Table.SelectRows(
                                files,
                                each [Extension] = EXTENSION
                            ),
                    results = Table.RowCount(filter),
                    module = List.Transform(
                                    filter[Name],
                                    each Text.BeforeDelimiter(
                                        _,
                                        EXTENSION,
                                        {0,RelativePosition.FromEnd}
                                    )
                                )
                ],
                each [
                    folder = [folder],
                    module = [module],
                    results = [results]
                ]
            ),
            Return = Table.ExpandListColumn(
                            Table.FromRecords(
                                List.Select(Files, each [results]>0)
                            ),
                            "module"
                        )
        in
            Return,

    /* Import module (first match) from the list of possible locations */
    Module.ImportAny = (name as text, locations as list, optional local as logical) =>
        let
            Paths = List.Transform(
                        locations,
                        each Module.BuildPath(name, _, local)
                    ),
            Loop = List.Generate(
                () => [i=-1, object=null],
                each [i] < List.Count(Paths),
                each [
                    i = [i] + 1,
                    object = if [object] is null
                             then try Module.FromPath(Paths{i}, local)
                                  otherwise null
                             else [object]
                ],
                each [object]
            ),
            Return = try
                        List.Select(Loop, each _ <> null){0}
                     otherwise
                        error "Module.ImportAny: `" & name & "` not found"
        in
            Return,

    /* Import a module from default locations (LibPQ.Sources) */
    Module.Import = (name as text) =>
             try
                Record.Field(#shared, name)
             otherwise try
                Record.Field(Helpers, name)
             otherwise try
                Module.ImportAny(name, Sources.Local)
             otherwise try
                Module.ImportAny(name, Sources.Web, false)
             otherwise
                error "Module.Import: `" & name & "` not found",


    /* Playground */
    Directory = "C:\Users\Виталий\Desktop\LibPQ\Functions\",
    File = "C:\Users\Виталий\Desktop\LibPQ\Functions\fnReadParameters.m",
    Url = "https://raw.githubusercontent.com/tycho01/pquery/master/Load.pq",
    Sources.Web = {"https://raw.githubusercontent.com/tycho01/pquery/master/"},
    Sources.Local = {Directory, "C:\Users\Виталий\Desktop\Номенклатура", "M:\Виталий Потяркин", "C:\Pquer"},

    ReturnDebug = Module.Import("fnReadParameters"),


    /* Last touch: export helper functions defined above */
    Helpers = [
        Text.Load = Text.Load,
        Module.FromPath = Module.FromPath,
        Module.Explore = Module.Explore,
        Module.Import = Module.Import,
        Module.ImportAny = Module.ImportAny,
        Module.BuildPath = Module.BuildPath
    ],
    Library = "A record with all loaded functions", // TODO
    Return = Record.Combine({Helpers, Library})
in
    ReturnDebug
