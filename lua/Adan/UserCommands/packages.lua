vim.api.nvim_create_user_command('MasonRefresh', function()
  require('mason-registry').refresh()
end, {})

---@class TSVendor.GitResult
---@field code integer
---@field stderr? string

---@param repo string "owner/repo" GitHub path
---@param callback fun(tmp_dir: string|nil)
local function git_shallow_clone(repo, callback)
  local tmp = vim.fn.tempname()
  ---@type string[]
  local args = {
    'git',
    'clone',
    '--depth=1',
    '--filter=blob:none',
    '--sparse',
    '--quiet',
    'https://github.com/' .. repo,
    tmp,
  }
  vim.system(args, { text = true }, function(res)
    if res.code ~= 0 then
      vim.schedule(function()
        vim.notify(
          string.format('TSVendor: git clone failed for %s\n%s', repo, res.stderr or ''),
          vim.log.levels.ERROR
        )
      end)
      callback(nil)
    else
      callback(tmp)
    end
  end)
end

---@param tmp_dir string
---@param sparse_path string Path inside the repo to sparse-checkout, e.g. "runtime/queries"
---@param callback fun(ok: boolean)
local function git_sparse_checkout(tmp_dir, sparse_path, callback)
  vim.system(
    { 'git', '-C', tmp_dir, 'sparse-checkout', 'set', '--no-cone', sparse_path },
    { text = true },
    function(res)
      if res.code ~= 0 then
        vim.schedule(function()
          vim.notify(
            string.format(
              'TSVendor: sparse-checkout failed for %s\n%s',
              sparse_path,
              res.stderr or ''
            ),
            vim.log.levels.ERROR
          )
        end)
        callback(false)
      else
        callback(true)
      end
    end
  )
end

-- TSVendor command ---------------------------------------------------------

vim.api.nvim_create_user_command('TSVendor', function()
  local queries_dir = vim.fn.stdpath('config') .. '/after/queries'

  ---@type Adan.TSVendorSpec[]
  local source_specs = {
    {
      name = 'tree-sitter-manager',
      repo = 'romus204/tree-sitter-manager.nvim',
      queries_path = 'runtime/queries',
      exclude = { ['textobjects.scm'] = true },
    },
    {
      name = 'nvim-treesitter-textobjects',
      repo = 'nvim-treesitter/nvim-treesitter-textobjects',
      queries_path = 'queries',
      filename = 'textobjects.scm',
    },
    {
      name = 'nvim-treesitter-context',
      repo = 'nvim-treesitter/nvim-treesitter-context',
      queries_path = 'queries',
      filename = 'context.scm',
    },
  }

  ---@type integer
  local installed = 0
  ---@type string[]
  local failed = {}
  ---@type integer
  local phases_done = 0
  local total_phases = #source_specs

  local function check_complete()
    if phases_done == total_phases then
      vim.schedule(function()
        vim.notify(
          string.format('TSVendor: %d files installed, %d failed', installed, #failed),
          vim.log.levels.INFO
        )
        if #failed > 0 then
          vim.notify('TSVendor failed:\n' .. table.concat(failed, '\n'), vim.log.levels.WARN)
        end
      end)
    end
  end

  ---@param src string Absolute path to source file
  ---@param dst string Absolute path to destination file
  ---@param label string Relative path used in failure messages, e.g. "lua/highlights.scm"
  local function copy_file(src, dst, label)
    local ok, err = vim.uv.fs_copyfile(src, dst)
    if ok then
      installed = installed + 1
    else
      table.insert(failed, string.format('%s (%s)', label, err or 'unknown error'))
    end
  end

  ---@param spec Adan.TSVendorSpec
  ---@param tmp_dir string
  local function install_files(spec, tmp_dir)
    local src_queries = tmp_dir .. '/' .. spec.queries_path

    local top_handle, err = vim.uv.fs_scandir(src_queries)
    if not top_handle then
      vim.schedule(function()
        vim.notify(
          string.format('TSVendor: could not scan queries dir from %s: %s', spec.name, err or ''),
          vim.log.levels.ERROR
        )
      end)
      return
    end

    ---@type string[]
    local langs = {}
    while true do
      local entry_name, entry_type = vim.uv.fs_scandir_next(top_handle)
      if not entry_name then
        break
      end
      if entry_type == 'directory' then
        table.insert(langs, entry_name)
      end
    end

    vim.schedule(function()
      vim.notify(
        string.format('TSVendor: installing %d languages from %s', #langs, spec.name),
        vim.log.levels.INFO
      )

      for _, lang in ipairs(langs) do
        local src_lang = src_queries .. '/' .. lang
        local dst_lang = queries_dir .. '/' .. lang
        vim.fn.mkdir(dst_lang, 'p')

        if spec.filename then
          local src = src_lang .. '/' .. spec.filename
          if vim.uv.fs_stat(src) then
            copy_file(src, dst_lang .. '/' .. spec.filename, lang .. '/' .. spec.filename)
          end
        else
          local lang_handle = vim.uv.fs_scandir(src_lang)
          if lang_handle then
            while true do
              local fname = vim.uv.fs_scandir_next(lang_handle)
              if not fname then
                break
              end
              if fname:match('%.scm$') and not (spec.exclude or {})[fname] then
                copy_file(src_lang .. '/' .. fname, dst_lang .. '/' .. fname, lang .. '/' .. fname)
              end
            end
          end
        end
      end

      vim.fn.delete(tmp_dir, 'rf')
      phases_done = phases_done + 1
      check_complete()
    end)
  end

  ---@param spec Adan.TSVendorSpec
  local function run_phase(spec)
    vim.notify('TSVendor: cloning ' .. spec.name .. '...', vim.log.levels.INFO)

    git_shallow_clone(spec.repo, function(tmp_dir)
      if not tmp_dir then
        phases_done = phases_done + 1
        check_complete()
        return
      end

      git_sparse_checkout(tmp_dir, spec.queries_path, function(ok)
        if not ok then
          vim.fn.delete(tmp_dir, 'rf')
          phases_done = phases_done + 1
          check_complete()
          return
        end

        install_files(spec, tmp_dir)
      end)
    end)
  end

  for _, spec in ipairs(source_specs) do
    run_phase(spec)
  end
end, {
  desc = 'Vendor all treesitter query files from tree-sitter-manager and nvim-treesitter-textobjects',
})

-- TSBuildParser command ------------------------------------------------------
---@class Adan.TSParserSpec
---@field repo? string "owner/repo" on GitHub (shorthand -- used when url is absent)
---@field url? string  full git clone URL, for non-GitHub hosts (GitLab,
---                     sourcehut, Codeberg, ...). Takes precedence over repo.
---@field path? string subdirectory containing grammar.js/src, for repos
---                     that bundle multiple grammars (e.g. typescript/tsx)

---@type table<string, Adan.TSParserSpec>
local parser_specs = {
  abl = { repo = 'usagi-coffee/tree-sitter-abl' },
  ada = { repo = 'briot/tree-sitter-ada' },
  agda = { repo = 'tree-sitter/tree-sitter-agda' },
  al = { repo = 'SShadowS/tree-sitter-al' },
  angular = { repo = 'dlvandenberg/tree-sitter-angular' },
  apex = { repo = 'aheber/tree-sitter-sfapex', path = 'apex' },
  arduino = { repo = 'tree-sitter-grammars/tree-sitter-arduino' },
  asciidoc = { repo = 'cathaysia/tree-sitter-asciidoc', path = 'tree-sitter-asciidoc' },
  asciidoc_inline = {
    repo = 'cathaysia/tree-sitter-asciidoc',
    path = 'tree-sitter-asciidoc_inline',
  },
  asm = { repo = 'rush-rs/tree-sitter-asm' },
  astro = { repo = 'virchau13/tree-sitter-astro' },
  authzed = { repo = 'mleonidas/tree-sitter-authzed' },
  awk = { repo = 'Beaglefoot/tree-sitter-awk' },
  bash = { repo = 'tree-sitter/tree-sitter-bash' },
  bass = { repo = 'vito/tree-sitter-bass' },
  batch = { repo = 'wharflab/tree-sitter-batch' },
  bazelrc = { repo = 'zaucy/tree-sitter-bazelrc' },
  beancount = { repo = 'polarmutex/tree-sitter-beancount' },
  bibtex = { repo = 'latex-lsp/tree-sitter-bibtex' },
  bicep = { repo = 'tree-sitter-grammars/tree-sitter-bicep' },
  bison = { url = 'https://gitlab.com/btuin2/tree-sitter-bison' },
  bitbake = { repo = 'tree-sitter-grammars/tree-sitter-bitbake' },
  blueprint = { url = 'https://gitlab.com/gabmus/tree-sitter-blueprint' },
  boogie = { repo = 'katrinafyi/tree-sitter-boogie' },
  bp = { repo = 'ambroisie/tree-sitter-bp' },
  brightscript = { repo = 'ajdelcimmuto/tree-sitter-brightscript' },
  c = { repo = 'tree-sitter/tree-sitter-c' },
  c3 = { repo = 'c3lang/tree-sitter-c3' },
  c_sharp = { repo = 'tree-sitter/tree-sitter-c-sharp' },
  caddy = { repo = 'opa-oz/tree-sitter-caddy' },
  cairo = { repo = 'tree-sitter-grammars/tree-sitter-cairo' },
  capnp = { repo = 'tree-sitter-grammars/tree-sitter-capnp' },
  carve = { repo = 'markup-cave/tree-sitter-carve' },
  cedar = { repo = 'chrnorm/tree-sitter-cedar' },
  cel = { repo = 'bufbuild/tree-sitter-cel' },
  cfengine = { repo = 'olehermanse/tree-sitter-cfengine' },
  cfhtml = { repo = 'cfmleditor/tree-sitter-cfml', path = 'cfml' },
  cfml = { repo = 'cfmleditor/tree-sitter-cfml', path = 'cfml' },
  cfquery = { repo = 'cfmleditor/tree-sitter-cfml', path = 'cfquery' },
  cfscript = { repo = 'cfmleditor/tree-sitter-cfml', path = 'cfscript' },
  chatito = { repo = 'tree-sitter-grammars/tree-sitter-chatito' },
  chatl = { repo = 'tree-sitter-grammars/tree-sitter-chatito' },
  chuck = { repo = 'tymbalodeon/tree-sitter-chuck' },
  circom = { repo = 'Decurity/tree-sitter-circom' },
  clean = { repo = 'ishaq2321/tree-sitter-clean' },
  clojure = { repo = 'sogaiu/tree-sitter-clojure' },
  cmake = { repo = 'uyha/tree-sitter-cmake' },
  cobol = { repo = 'yutaro-sakamoto/tree-sitter-cobol' },
  comment = { repo = 'stsewd/tree-sitter-comment' },
  commonlisp = { repo = 'theHamsta/tree-sitter-commonlisp' },
  containerfile = { repo = 'wharflab/tree-sitter-containerfile' },
  context = { repo = 'pmazaitis/tree-sitter-context_en' },
  cooklang = { repo = 'addcninblue/tree-sitter-cooklang' },
  core_schema = { repo = 'tree-sitter-grammars/tree-sitter-yaml', path = 'schema/core' },
  corn = { repo = 'jakestanger/tree-sitter-corn' },
  cpon = { repo = 'tree-sitter-grammars/tree-sitter-cpon' },
  cpp = { repo = 'tree-sitter/tree-sitter-cpp' },
  cql = { repo = 'ricomariani/tree-sitter-cgsql' },
  crystal = { repo = 'keidax/tree-sitter-crystal' },
  css = { repo = 'tree-sitter/tree-sitter-css' },
  csv = { repo = 'tree-sitter-grammars/tree-sitter-csv', path = 'csv' },
  cuda = { repo = 'tree-sitter-grammars/tree-sitter-cuda' },
  cue = { repo = 'eonpatapon/tree-sitter-cue' },
  cylc = { repo = 'elliotfontaine/tree-sitter-cylc' },
  d = { repo = 'gdamore/tree-sitter-d' },
  dafny = { repo = 'hath995/tree-sitter-dafny' },
  dart = { repo = 'UserNobody14/tree-sitter-dart' },
  dbml = { repo = 'gsihaj5/tree-sitter-dbml' },
  desktop = { repo = 'ValdezFOmar/tree-sitter-desktop' },
  devicetree = { repo = 'joelspadin/tree-sitter-devicetree' },
  dhall = { repo = 'jbellerb/tree-sitter-dhall' },
  diff = { repo = 'the-mikedavis/tree-sitter-diff' },
  disassembly = { repo = 'ColinKennedy/tree-sitter-disassembly' },
  djot = { repo = 'treeman/tree-sitter-djot' },
  dockerfile = { repo = 'camdencheek/tree-sitter-dockerfile' },
  dot = { repo = 'rydesun/tree-sitter-dot' },
  doxygen = { repo = 'tree-sitter-grammars/tree-sitter-doxygen' },
  drools = { repo = 'iByteABit256/tree-sitter-drools' },
  dtd = { repo = 'tree-sitter-grammars/tree-sitter-xml', path = 'dtd' },
  earthfile = { repo = 'glehmann/tree-sitter-earthfile' },
  ebnf = { repo = 'RubixDev/ebnf' },
  editorconfig = { repo = 'ValdezFOmar/tree-sitter-editorconfig' },
  eds = { repo = 'uyha/tree-sitter-eds' },
  eex = { repo = 'connorlay/tree-sitter-eex' },
  elisp = { repo = 'Wilfred/tree-sitter-elisp' },
  elixir = { repo = 'elixir-lang/tree-sitter-elixir' },
  elm = { repo = 'elm-tooling/tree-sitter-elm' },
  elsa = { repo = 'glapa-grossklag/tree-sitter-elsa' },
  elvish = { repo = 'elves/tree-sitter-elvish' },
  embedded_template = { repo = 'tree-sitter/tree-sitter-embedded-template' },
  enforce = { repo = 'simonvic/tree-sitter-enforce' },
  erlang = { repo = 'WhatsApp/tree-sitter-erlang' },
  eventrule = { repo = '3p3r/tree-sitter-eventrule' },
  facility = { repo = 'FacilityApi/tree-sitter-facility' },
  faust = { repo = 'khiner/tree-sitter-faust' },
  fennel = { repo = 'alexmozaidze/tree-sitter-fennel' },
  fidl = { repo = 'google/tree-sitter-fidl' },
  firrtl = { repo = 'tree-sitter-grammars/tree-sitter-firrtl' },
  fish = { repo = 'ram02z/tree-sitter-fish' },
  fluentbit = { repo = 'sh-cho/tree-sitter-fluentbit' },
  foam = { repo = 'FoamScience/tree-sitter-foam' },
  formula = { repo = 'siraben/tree-sitter-formula' },
  forth = { repo = 'AlexanderBrevig/tree-sitter-forth' },
  fortran = { repo = 'stadelmanma/tree-sitter-fortran' },
  fsh = { repo = 'mgramigna/tree-sitter-fsh' },
  fsharp = { repo = 'ionide/tree-sitter-fsharp', path = 'fsharp' },
  fsharp_signature = { repo = 'ionide/tree-sitter-fsharp', path = 'fsharp_signature' },
  func = { repo = 'tree-sitter-grammars/tree-sitter-func' },
  fusion = { url = 'https://gitlab.com/jirgn/tree-sitter-fusion' },
  gap = { repo = 'gap-system/tree-sitter-gap' },
  gaptst = { repo = 'gap-system/tree-sitter-gaptst' },
  gdscript = { repo = 'PrestonKnopp/tree-sitter-gdscript' },
  gdshader = { repo = 'airblast-dev/tree-sitter-gdshader' },
  gemini = { url = 'https://git.sr.ht/~nbsp/tree-sitter-gemini' },
  gemtext = { repo = 'pebbe/tree-sitter-gemtext' },
  ghccore = { repo = 'bgamari/tree-sitter-ghc-core' },
  git_commit = { repo = 'the-mikedavis/tree-sitter-git-commit' },
  git_config = { repo = 'the-mikedavis/tree-sitter-git-config' },
  git_rebase = { repo = 'the-mikedavis/tree-sitter-git-rebase' },
  gitattributes = { repo = 'tree-sitter-grammars/tree-sitter-gitattributes' },
  gitcommit = { repo = 'gbprod/tree-sitter-gitcommit' },
  gitignore = { repo = 'shunsambongi/tree-sitter-gitignore' },
  gleam = { repo = 'gleam-lang/tree-sitter-gleam' },
  glimmer = { repo = 'ember-tooling/tree-sitter-glimmer' },
  glimmer_javascript = { repo = 'NullVoxPopuli/tree-sitter-glimmer-javascript' },
  glimmer_typescript = { repo = 'NullVoxPopuli/tree-sitter-glimmer-typescript' },
  glsl = { repo = 'tree-sitter-grammars/tree-sitter-glsl' },
  gn = { repo = 'tree-sitter-grammars/tree-sitter-gn' },
  gnuplot = { repo = 'dpezto/tree-sitter-gnuplot' },
  go = { repo = 'tree-sitter/tree-sitter-go' },
  goctl = { repo = 'chaozwn/tree-sitter-goctl' },
  godot_resource = { repo = 'PrestonKnopp/tree-sitter-godot-resource' },
  gomod = { repo = 'camdencheek/tree-sitter-go-mod' },
  gosum = { repo = 'tree-sitter-grammars/tree-sitter-go-sum' },
  gotmpl = { repo = 'ngalaiko/tree-sitter-go-template' },
  gowork = { repo = 'omertuc/tree-sitter-go-work' },
  gpg = { repo = 'tree-sitter-grammars/tree-sitter-gpg-config' },
  graphql = { repo = '11bit/tree-sitter-graphql' },
  gren = { repo = 'MaeBrooks/tree-sitter-gren' },
  groovy = { repo = 'murtaza64/tree-sitter-groovy' },
  groq = { repo = 'ajrussellaudio/tree-sitter-groq' },
  gstlaunch = { repo = 'theHamsta/tree-sitter-gstlaunch' },
  gularen = { repo = 'noorwachid/tree-sitter-gularen' },
  hack = { repo = 'slackhq/tree-sitter-hack' },
  hare = { repo = 'tree-sitter-grammars/tree-sitter-hare' },
  haskell = { repo = 'tree-sitter/tree-sitter-haskell' },
  haskell_persistent = { repo = 'MercuryTechnologies/tree-sitter-haskell-persistent' },
  haxe = { repo = 'vantreeseba/tree-sitter-haxe' },
  hcl = { repo = 'tree-sitter-grammars/tree-sitter-hcl' },
  heex = { repo = 'connorlay/tree-sitter-heex' },
  helm = { repo = 'ngalaiko/tree-sitter-go-template' },
  helma = { repo = 'kevinkeckeis/tree-sitter-helma' },
  hjson = { repo = 'winston0410/tree-sitter-hjson' },
  hlsl = { repo = 'tree-sitter-grammars/tree-sitter-hlsl' },
  hlsplaylist = { repo = 'Freed-Wu/tree-sitter-hlsplaylist' },
  hocon = { repo = 'antosha417/tree-sitter-hocon' },
  hoon = { repo = 'urbit-pilled/tree-sitter-hoon' },
  html = { repo = 'EmranMR/tree-sitter-blade' },
  htmldjango = { repo = 'interdependence/tree-sitter-htmldjango' },
  http = { repo = 'rest-nvim/tree-sitter-http' },
  hurl = { repo = 'pfeiferj/tree-sitter-hurl' },
  hyprlang = { repo = 'tree-sitter-grammars/tree-sitter-hyprlang' },
  ibmhlasm = { repo = 'janus-llm/tree-sitter-ibmhlasm' },
  idl = { repo = 'cathaysia/tree-sitter-idl' },
  idris = { repo = 'kayhide/tree-sitter-idris' },
  idris2 = { repo = 'gwerbin/tree-sitter-idris2' },
  iex = { repo = 'elixir-lang/tree-sitter-iex' },
  ini = { repo = 'justinmk/tree-sitter-ini' },
  inko = { repo = 'inko-lang/tree-sitter-inko' },
  ispc = { repo = 'tree-sitter-grammars/tree-sitter-ispc' },
  jack = { repo = 'nverno/tree-sitter-jack' },
  jakt = { repo = 'demizer/tree-sitter-jakt' },
  janet = { repo = 'GrayJack/tree-sitter-janet' },
  janet_simple = { repo = 'sogaiu/tree-sitter-janet-simple' },
  java = { repo = 'tree-sitter/tree-sitter-java' },
  javadoc = { repo = 'rmuir/tree-sitter-javadoc' },
  javascript = { repo = 'tree-sitter/tree-sitter-javascript' },
  jinja2 = { repo = 'dbt-labs/tree-sitter-jinja2' },
  jpp = { repo = 'nitreojs/tree-sitter-jpp' },
  jq = { repo = 'flurie/tree-sitter-jq' },
  jsdoc = { repo = 'tree-sitter/tree-sitter-jsdoc' },
  json = { repo = 'tree-sitter/tree-sitter-json' },
  json5 = { repo = 'Joakker/tree-sitter-json5' },
  json_schema = { repo = 'tree-sitter-grammars/tree-sitter-yaml', path = 'schema/json' },
  jsonc = { url = 'https://gitlab.com/WhyNotHugo/tree-sitter-jsonc' },
  jsonnet = { repo = 'sourcegraph/tree-sitter-jsonnet' },
  julia = { repo = 'tree-sitter/tree-sitter-julia' },
  just = { repo = 'IndianBoy42/tree-sitter-just' },
  kcl = { repo = 'kcl-lang/tree-sitter-kcl' },
  kconfig = { repo = 'tree-sitter-grammars/tree-sitter-kconfig' },
  kdl = { repo = 'tree-sitter-grammars/tree-sitter-kdl' },
  koka = { repo = 'mtoohey31/tree-sitter-koka' },
  kotlin = { repo = 'fwcd/tree-sitter-kotlin' },
  koto = { repo = 'koto-lang/tree-sitter-koto' },
  kusto = { repo = 'Willem-J-an/tree-sitter-kusto' },
  lalrpop = { repo = 'traxys/tree-sitter-lalrpop' },
  latex = { repo = 'latex-lsp/tree-sitter-latex' },
  lean = { repo = 'Julian/tree-sitter-lean' },
  ledger = { repo = 'cbarrete/tree-sitter-ledger' },
  legacy_schema = { repo = 'tree-sitter-grammars/tree-sitter-yaml', path = 'schema/legacy' },
  leo = { repo = 'r001/tree-sitter-leo' },
  lilypond = { repo = 'tristanperalta/tree-sitter-lilypond' },
  linkerscript = { repo = 'tree-sitter-grammars/tree-sitter-linkerscript' },
  liquid = { repo = 'hankthetank27/tree-sitter-liquid' },
  liquidsoap = { repo = 'savonet/tree-sitter-liquidsoap' },
  llvm = { repo = 'benwilliamgraham/tree-sitter-llvm' },
  llvm_mir = { repo = 'Flakebi/tree-sitter-llvm-mir' },
  lua = { repo = 'tree-sitter-grammars/tree-sitter-lua' },
  luadoc = { repo = 'tree-sitter-grammars/tree-sitter-luadoc' },
  luap = { repo = 'tree-sitter-grammars/tree-sitter-luap' },
  luau = { repo = 'polychromatist/tree-sitter-luau' },
  m68k = { repo = 'grahambates/tree-sitter-m68k' },
  magik = { repo = 'krn-robin/tree-sitter-magik' },
  mail = { repo = 'stevenxxiu/tree-sitter-mail' },
  make = { repo = 'tree-sitter-grammars/tree-sitter-make' },
  mal = { repo = 'sogaiu/tree-sitter-mal' },
  mandbconfig = { repo = 'TornaxO7/tree-sitter-man-db-config' },
  markdown = { repo = 'tree-sitter-grammars/tree-sitter-markdown', path = 'tree-sitter-markdown' },
  markdown_inline = {
    repo = 'tree-sitter-grammars/tree-sitter-markdown',
    path = 'tree-sitter-markdown-inline',
  },
  math = { repo = 'DerekStride/tree-sitter-math' },
  matlab = { repo = 'acristoffers/tree-sitter-matlab' },
  mcfunction = { repo = 'bbfh-dev/tree-sitter-mcfunction' },
  menhir = { repo = 'Kerl13/tree-sitter-menhir' },
  mermaid = { repo = 'monaqa/tree-sitter-mermaid' },
  meson = { repo = 'Decodetalkers/tree-sitter-meson' },
  mlir = { repo = 'artagnon/tree-sitter-mlir' },
  modelica = { repo = 'modelicahub/tree-sitter-modelica' },
  monkey = { repo = 'jamestrew/tree-sitter-monkey' },
  move = { repo = 'tree-sitter-grammars/tree-sitter-move' },
  muttrc = { repo = 'neomutt/tree-sitter-muttrc' },
  nasm = { repo = 'naclsn/tree-sitter-nasm' },
  nginx = { repo = 'opa-oz/tree-sitter-nginx' },
  nickel = { repo = 'nickel-lang/tree-sitter-nickel' },
  nim = { repo = 'alaviss/tree-sitter-nim' },
  nim_format_string = { repo = 'aMOPel/tree-sitter-nim-format-string' },
  ninja = { repo = 'alemuller/tree-sitter-ninja' },
  nix = { repo = 'nix-community/tree-sitter-nix' },
  noir = { repo = 'hhamud/tree-sitter-noir' },
  nois = { repo = 'nois-lang/tree-sitter-nois' },
  norg_meta = { repo = 'nvim-neorg/tree-sitter-norg-meta' },
  nqc = { repo = 'tree-sitter-grammars/tree-sitter-nqc' },
  nu = { repo = 'nushell/tree-sitter-nu' },
  objc = { repo = 'tree-sitter-grammars/tree-sitter-objc' },
  objdump = { repo = 'ColinKennedy/tree-sitter-objdump' },
  ocaml = { repo = 'tree-sitter/tree-sitter-ocaml', path = 'grammars/ocaml' },
  ocaml_interface = { repo = 'tree-sitter/tree-sitter-ocaml', path = 'grammars/interface' },
  ocaml_type = { repo = 'tree-sitter/tree-sitter-ocaml', path = 'grammars/type' },
  ocamllex = { repo = 'atom-ocaml/tree-sitter-ocamllex' },
  odin = { repo = 'tree-sitter-grammars/tree-sitter-odin' },
  ohm = { repo = 'novusnota/tree-sitter-ohm' },
  openscad = { repo = 'bollian/tree-sitter-openscad' },
  org = { repo = 'milisims/tree-sitter-org' },
  p4 = { repo = 'ace-design/tree-sitter-p4' },
  papyrus = { repo = 'open-papyrus/tree-sitter-papyrus' },
  pascal = { repo = 'Isopod/tree-sitter-pascal' },
  passwd = { repo = 'ath3/tree-sitter-passwd' },
  pem = { repo = 'tree-sitter-grammars/tree-sitter-pem' },
  perl = { repo = 'tree-sitter-perl/tree-sitter-perl' },
  pgn = { repo = 'rolandwalker/tree-sitter-pgn' },
  php = { repo = 'tree-sitter/tree-sitter-php', path = 'php' },
  php_only = { repo = 'tree-sitter/tree-sitter-php', path = 'php_only' },
  phpdoc = { repo = 'claytonrcarter/tree-sitter-phpdoc' },
  pioasm = { repo = 'leo60228/tree-sitter-pioasm' },
  pkl = { repo = 'apple/tree-sitter-pkl' },
  plantuml = { repo = 'Decodetalkers/tree_sitter_plantuml' },
  po = { repo = 'tree-sitter-grammars/tree-sitter-po' },
  pod = { repo = 'tree-sitter-perl/tree-sitter-pod' },
  poe_filter = { repo = 'tree-sitter-grammars/tree-sitter-poe-filter' },
  pony = { repo = 'tree-sitter-grammars/tree-sitter-pony' },
  posix_awk = { repo = 'konomanoasa/tree-sitter-posix-awk' },
  powershell = { repo = 'wharflab/tree-sitter-powershell' },
  printf = { repo = 'tree-sitter-grammars/tree-sitter-printf' },
  prisma = { repo = 'victorhqc/tree-sitter-prisma' },
  problog = { url = 'https://codeberg.org/foxy/tree-sitter-prolog' }, -- TODO: verify subdir on Codeberg (shared repo with prolog)
  prolog = { url = 'https://codeberg.org/foxy/tree-sitter-prolog' }, -- TODO: verify subdir on Codeberg (shared repo with problog)
  promela = { repo = 'siraben/tree-sitter-promela' },
  promql = { repo = 'MichaHoffmann/tree-sitter-promql' },
  properties = { repo = 'tree-sitter-grammars/tree-sitter-properties' },
  proto = { repo = 'treywood/tree-sitter-proto' },
  prql = { repo = 'PRQL/tree-sitter-prql' },
  psv = { repo = 'tree-sitter-grammars/tree-sitter-csv', path = 'psv' },
  pug = { repo = 'zealot128/tree-sitter-pug' },
  puppet = { repo = 'tree-sitter-grammars/tree-sitter-puppet' },
  purescript = { repo = 'postsolar/tree-sitter-purescript' },
  pymanifest = { repo = 'tree-sitter-grammars/tree-sitter-pymanifest' },
  python = { repo = 'tree-sitter/tree-sitter-python' },
  ql = { repo = 'tree-sitter/tree-sitter-ql' },
  qmldir = { repo = 'Decodetalkers/tree-sitter-qmldir' },
  qmljs = { repo = 'yuja/tree-sitter-qmljs' },
  quakec = { repo = 'vkazanov/tree-sitter-quakec' },
  query = { repo = 'tree-sitter-grammars/tree-sitter-query' },
  r = { repo = 'r-lib/tree-sitter-r' },
  racket = { repo = '6cdh/tree-sitter-racket' },
  radvd = { repo = 'mdspan/tree-sitter-radvd' },
  ralph = { repo = 'alephium/tree-sitter-ralph' },
  rasi = { repo = 'Fymyte/tree-sitter-rasi' },
  razor = { repo = 'tris203/tree-sitter-razor' },
  rbs = { repo = 'joker1007/tree-sitter-rbs' },
  re2c = { repo = 'tree-sitter-grammars/tree-sitter-re2c' },
  readline = { repo = 'tree-sitter-grammars/tree-sitter-readline' },
  rec = { repo = 'amaanq/tree-sitter-rec' },
  regex = { repo = 'tree-sitter/tree-sitter-regex' },
  rego = { repo = 'FallenAngel97/tree-sitter-rego' },
  requirements = { repo = 'tree-sitter-grammars/tree-sitter-requirements' },
  rescript = { repo = 'rescript-lang/tree-sitter-rescript' },
  rnoweb = { repo = 'bamonroe/tree-sitter-rnoweb' },
  robot = { repo = 'Hubro/tree-sitter-robot' },
  robots = { repo = 'opa-oz/tree-sitter-robots-txt' },
  roc = { repo = 'faldor20/tree-sitter-roc' },
  ron = { repo = 'tree-sitter-grammars/tree-sitter-ron' },
  ros_interface = { repo = 'SuperJappie08/tree-sitter-ros-interface' },
  rpmbash = { url = 'https://gitlab.com/cryptomilk/tree-sitter-rpmspec' }, -- TODO: verify subdir on GitLab -- could not browse gitlab.com file tree
  rpmspec = { url = 'https://gitlab.com/cryptomilk/tree-sitter-rpmspec' },
  rst = { repo = 'stsewd/tree-sitter-rst' },
  rtf = { repo = 'GoodNotes/tree-sitter-rtf' },
  ruby = { repo = 'tree-sitter/tree-sitter-ruby' },
  runescript = { repo = '2004Scape/tree-sitter-runescript' },
  rust = { repo = 'tree-sitter/tree-sitter-rust' },
  sas = { repo = 'ix-infrastructure/tree-sitter-sas' },
  satysfi = { repo = 'monaqa/tree-sitter-satysfi' },
  scala = { repo = 'tree-sitter/tree-sitter-scala' },
  scfg = { repo = 'rockorager/tree-sitter-scfg' },
  scheme = { repo = '6cdh/tree-sitter-scheme' },
  scilab = { repo = 'nicolas-graves/tree-sitter-scilab' },
  scss = { repo = 'serenadeai/tree-sitter-scss' },
  sdml = { repo = 'sdm-lang/tree-sitter-sdml' },
  sed = { repo = 'konomanoasa/tree-sitter-sed' },
  sed_ere = { repo = 'konomanoasa/tree-sitter-sed', path = 'sed_ere' },
  sexp = { repo = 'AbstractMachinesLab/tree-sitter-sexp' },
  sflog = { repo = 'aheber/tree-sitter-sfapex', path = 'sflog' },
  sh = { repo = 'konomanoasa/tree-sitter-sh' },
  slang = { repo = 'theHamsta/tree-sitter-slang' },
  slim = { repo = 'theoo/tree-sitter-slim' },
  slint = { repo = 'slint-ui/tree-sitter-slint' },
  smali = { repo = 'tree-sitter-grammars/tree-sitter-smali' },
  smallbasic = { repo = 'comom87/tree-sitter-smallbasic' },
  smalltalk = { repo = 'tom95/tree-sitter-smalltalk' },
  smarty = { repo = 'Kibadda/tree-sitter-smarty' },
  smithy = { repo = 'indoorvivants/tree-sitter-smithy' },
  sml = { repo = 'MatthewFluet/tree-sitter-sml' },
  snakemake = { repo = 'osthomas/tree-sitter-snakemake' },
  solidity = { repo = 'JoranHonig/tree-sitter-solidity' },
  soql = { repo = 'aheber/tree-sitter-sfapex', path = 'soql' },
  sosl = { repo = 'aheber/tree-sitter-sfapex', path = 'sosl' },
  souffle = { repo = 'langston-barrett/tree-sitter-souffle' },
  sourcepawn = { repo = 'nilshelmig/tree-sitter-sourcepawn' },
  sparql = { repo = 'GordianDziwis/tree-sitter-sparql' },
  sqf = { repo = 'Tuupertunut/tree-sitter-sqf' },
  sql = { repo = 'DerekStride/tree-sitter-sql' },
  sql_bigquery = { repo = 'takegue/tree-sitter-sql-bigquery' },
  sqlite = { repo = 'dhcmrlchtdj/tree-sitter-sqlite' },
  squirrel = { repo = 'tree-sitter-grammars/tree-sitter-squirrel' },
  ssh_client_config = { repo = 'metio/tree-sitter-ssh-client-config' },
  ssh_config = { repo = 'tree-sitter-grammars/tree-sitter-ssh-config' },
  stan = { repo = 'WardBrian/tree-sitter-stan' },
  starlark = { repo = 'tree-sitter-grammars/tree-sitter-starlark' },
  strace = { repo = 'sigmaSd/tree-sitter-strace' },
  styled = { repo = 'mskelton/tree-sitter-styled' },
  supercollider = { repo = 'madskjeldgaard/tree-sitter-supercollider' },
  superhtml = { repo = 'kristoff-it/superhtml' },
  surface = { repo = 'connorlay/tree-sitter-surface' },
  surrealdb = { repo = 'DariusCorvus/tree-sitter-surrealdb' },
  svelte = { repo = 'tree-sitter-grammars/tree-sitter-svelte' },
  sway = { repo = 'FuelLabs/tree-sitter-sway' },
  swift = { repo = 'alex-pinkus/tree-sitter-swift' },
  sxhkdrc = { repo = 'RaafatTurki/tree-sitter-sxhkdrc' },
  systemrdl = { repo = 'SystemRDL/tree-sitter-systemrdl' },
  systemtap = { repo = 'ok-ryoko/tree-sitter-systemtap' },
  systemverilog = { repo = 'gmlarumbe/tree-sitter-systemverilog' },
  t32 = { url = 'https://codeberg.org/xasc/tree-sitter-t32' },
  tablegen = { repo = 'Flakebi/tree-sitter-tablegen' },
  tact = { repo = 'tact-lang/tree-sitter-tact' },
  tcl = { repo = 'tree-sitter-grammars/tree-sitter-tcl' },
  teal = { repo = 'euclidianAce/tree-sitter-teal' },
  templ = { repo = 'vrischmann/tree-sitter-templ' },
  tera = { repo = 'uncenter/tree-sitter-tera' },
  terraform = { repo = 'tree-sitter-grammars/tree-sitter-hcl' },
  textproto = { repo = 'PorterAtGoogle/tree-sitter-textproto' },
  thrift = { repo = 'tree-sitter-grammars/tree-sitter-thrift' },
  tiger = { repo = 'ambroisie/tree-sitter-tiger' },
  tlaplus = { repo = 'tlaplus-community/tree-sitter-tlaplus' },
  tmux = { repo = 'Freed-Wu/tree-sitter-tmux' },
  todotxt = { repo = 'arnarg/tree-sitter-todotxt' },
  toml = { repo = 'tree-sitter-grammars/tree-sitter-toml' },
  tsq = { repo = 'tree-sitter/tree-sitter-tsq' },
  tsv = { repo = 'tree-sitter-grammars/tree-sitter-csv', path = 'tsv' },
  tsx = { repo = 'tree-sitter/tree-sitter-typescript', path = 'tsx' },
  tucan = { repo = 'mrnugget/tree-sitter-tucan' },
  tucanir = { repo = 'mrnugget/tree-sitter-tucanir' },
  turtle = { repo = 'GordianDziwis/tree-sitter-turtle' },
  twig = { repo = 'gbprod/tree-sitter-twig' },
  twitchchat = { repo = 'rockerBOO/tree-sitter-twitchchat' },
  typescript = { repo = 'tree-sitter/tree-sitter-typescript', path = 'typescript' },
  typespec = { repo = 'happenslol/tree-sitter-typespec' },
  typoscript = { repo = 'Teddytrombone/tree-sitter-typoscript' },
  typst = { repo = 'uben0/tree-sitter-typst' },
  udev = { repo = 'tree-sitter-grammars/tree-sitter-udev' },
  ungrammar = { repo = 'tree-sitter-grammars/tree-sitter-ungrammar' },
  unified_diff = { repo = 'hsaliak/tree-sitter-unified-diff' },
  unifieddiff = { repo = 'monaqa/tree-sitter-unifieddiff' },
  unison = { repo = 'kylegoetz/tree-sitter-unison' },
  usd = { repo = 'ColinKennedy/tree-sitter-usd' },
  uxntal = { repo = 'tree-sitter-grammars/tree-sitter-uxntal' },
  v = { repo = 'vlang/v-analyzer' },
  vala = { repo = 'vala-lang/tree-sitter-vala' },
  varlink = { repo = 'bachorp/tree-sitter-varlink' },
  vba = { repo = 'arrmee-wt/tree-sitter-vba' },
  vbnet = { repo = 'CodeAnt-AI/tree-sitter-vb-dotnet' },
  vcard = { repo = 'TitouanReal/tree-sitter-vcard' },
  vcl = { repo = 'ntsk/tree-sitter-vcl' },
  vento = { repo = 'ventojs/tree-sitter-vento' },
  verilog = { repo = 'tree-sitter/tree-sitter-verilog' },
  vespa = { repo = 'bartek/tree-sitter-vespa' },
  vhdl = { repo = 'jpt13653903/tree-sitter-vhdl' },
  vhs = { repo = 'charmbracelet/tree-sitter-vhs' },
  vim = { repo = 'tree-sitter-grammars/tree-sitter-vim' },
  vimdoc = { repo = 'neovim/tree-sitter-vimdoc' },
  vrl = { repo = 'belltoy/tree-sitter-vrl' },
  vue = { repo = 'tree-sitter-grammars/tree-sitter-vue' },
  wast = { repo = 'wasm-lsp/tree-sitter-wasm' },
  wat = { repo = 'g-plane/tree-sitter-wat' },
  wgsl = { repo = 'gpuweb/tree-sitter-wgsl' },
  wgsl_bevy = { repo = 'tree-sitter-grammars/tree-sitter-wgsl-bevy' },
  wing = { repo = 'winglang/tree-sitter-wing' },
  wit = { repo = 'bytecodealliance/tree-sitter-wit' },
  x86asm = { repo = 'bearcove/tree-sitter-x86asm' },
  xcompose = { repo = 'tree-sitter-grammars/tree-sitter-xcompose' },
  xml = { repo = 'tree-sitter-grammars/tree-sitter-xml', path = 'xml' },
  xml_django = { repo = 'kraken-tech/tree-sitter-xml-django' },
  xquery = { repo = 'grantmacken/tree-sitter-xquery' },
  xresources = { repo = 'ValdezFOmar/tree-sitter-xresources' },
  yaml = { repo = 'tree-sitter-grammars/tree-sitter-yaml' },
  yang = { repo = 'Hubro/tree-sitter-yang' },
  yuck = { repo = 'tree-sitter-grammars/tree-sitter-yuck' },
  zathurarc = { repo = 'Freed-Wu/tree-sitter-zathurarc' },
  zeek = { repo = 'zeek/tree-sitter-zeek' },
  zig = { repo = 'tree-sitter-grammars/tree-sitter-zig' },
  ziggy = { repo = 'kristoff-it/ziggy', path = 'tree-sitter-ziggy' },
  ziggy_schema = { repo = 'kristoff-it/ziggy', path = 'tree-sitter-ziggy-schema' },
  zsh = { repo = 'georgeharker/tree-sitter-zsh' },
}

vim.api.nvim_create_user_command('TSBuildParser', function(opts)
  local lang = opts.args
  local spec = parser_specs[lang]

  if not spec then
    vim.notify(
      string.format(
        'TSBuildParser: no spec for "%s". Known: %s',
        lang,
        table.concat(vim.tbl_keys(parser_specs), ', ')
      ),
      vim.log.levels.ERROR
    )
    return
  end

  if vim.fn.executable('tree-sitter') == 0 then
    vim.notify(
      'TSBuildParser: "tree-sitter" CLI not found on PATH.\n'
        .. 'Install: npm install -g tree-sitter-cli  (or) cargo install tree-sitter-cli',
      vim.log.levels.ERROR
    )
    return
  end

  ---@type { cmd: string, prefix?: string[] }[]
  local compiler_candidates = {
    { cmd = 'cc' },
    { cmd = 'gcc' },
    { cmd = 'clang' },
    { cmd = 'zig', prefix = { 'cc' } },
  }
  local compiler, compiler_prefix
  for _, c in ipairs(compiler_candidates) do
    if vim.fn.executable(c.cmd) == 1 then
      compiler = c.cmd
      compiler_prefix = c.prefix or {}
      break
    end
  end
  if not compiler then
    vim.notify(
      'TSBuildParser: no C compiler found (looked for cc, gcc, clang, zig).\n'
        .. 'Install one -- zig (https://ziglang.org/download/) is a good cross-platform pick.',
      vim.log.levels.ERROR
    )
    return
  end

  vim.notify(string.format('TSBuildParser: cloning %s...', spec.repo), vim.log.levels.INFO)

  -- NOTE: deliberately NOT git_shallow_clone -- that helper does a
  -- --sparse clone for TSVendor's narrow "just fetch one queries/
  -- subfolder" use case, and only materializes files once
  -- git_sparse_checkout is called afterward with a specific path.
  -- A grammar repo's layout isn't known ahead of time, so this needs
  -- everything actually checked out.
  local tmp_dir = vim.fn.tempname()
  vim.system(
    { 'git', 'clone', '--depth=1', '--quiet', 'https://github.com/' .. spec.repo, tmp_dir },
    { text = true },
    function(clone_res)
      if clone_res.code ~= 0 then
        vim.schedule(function()
          vim.notify(
            string.format(
              'TSBuildParser: clone failed for %s\n%s',
              spec.repo,
              clone_res.stderr or ''
            ),
            vim.log.levels.ERROR
          )
        end)
        return
      end

      vim.schedule(function()
        local grammar_dir = spec.path and (tmp_dir .. '/' .. spec.path) or tmp_dir
        local parser_dir = vim.fn.stdpath('config') .. '/parser'
        vim.fn.mkdir(parser_dir, 'p')
        local out_path = parser_dir .. '/' .. lang .. '.so'

        -- Some repos don't commit src/grammar.json even though they commit
        -- src/parser.c. Regenerate to guarantee both exist and are in sync.
        vim.notify(string.format('TSBuildParser: generating %s...', lang), vim.log.levels.INFO)

        vim.system(
          { 'tree-sitter', 'generate' },
          { text = true, cwd = grammar_dir },
          function(gen_res)
            vim.schedule(function()
              if gen_res.code ~= 0 then
                vim.fn.delete(tmp_dir, 'rf')
                vim.notify(
                  string.format(
                    'TSBuildParser: generate failed for %s\n%s',
                    lang,
                    gen_res.stderr or ''
                  ),
                  vim.log.levels.ERROR
                )
                return
              end

              local src_dir = grammar_dir .. '/src'
              local sources = { src_dir .. '/parser.c' }
              local needs_cpp = false
              if vim.uv.fs_stat(src_dir .. '/scanner.c') then
                table.insert(sources, src_dir .. '/scanner.c')
              elseif vim.uv.fs_stat(src_dir .. '/scanner.cc') then
                table.insert(sources, src_dir .. '/scanner.cc')
                needs_cpp = true
              elseif vim.uv.fs_stat(src_dir .. '/scanner.cpp') then
                table.insert(sources, src_dir .. '/scanner.cpp')
                needs_cpp = true
              end

              local build_cmd = { compiler }
              vim.list_extend(build_cmd, compiler_prefix)
              vim.list_extend(build_cmd, { '-shared', '-fPIC', '-Os', '-I', src_dir })
              vim.list_extend(build_cmd, sources)
              vim.list_extend(build_cmd, { '-o', out_path })
              if needs_cpp then
                table.insert(build_cmd, '-lstdc++')
              end

              vim.notify(
                string.format('TSBuildParser: building %s with %s...', lang, compiler),
                vim.log.levels.INFO
              )

              vim.system(build_cmd, { text = true }, function(build_res)
                vim.schedule(function()
                  vim.fn.delete(tmp_dir, 'rf')
                  if build_res.code ~= 0 then
                    vim.notify(
                      string.format(
                        'TSBuildParser: build failed for %s\n%s',
                        lang,
                        build_res.stderr or ''
                      ),
                      vim.log.levels.ERROR
                    )
                  else
                    vim.notify(
                      string.format('TSBuildParser: built %s -> %s', lang, out_path),
                      vim.log.levels.INFO
                    )
                  end
                end)
              end)
            end)
          end
        )
      end)
    end
  )
end, {
  nargs = 1,
  complete = function()
    return vim.tbl_keys(parser_specs)
  end,
  desc = 'Clone and build a tree-sitter parser into the local parser/ directory',
})
