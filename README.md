# XML Converter Plugin

Converts JATS-XML and TEI-XML formats in OJS, supporting interoperability between publication systems (OJS, Lodel, Janeway). Developed by [TIB](https://www.tib.eu) with [OpenEdition](https://www.openedition.org/) as part of [Craft-OA](https://www.craft-oa.eu/), using [Métopes](https://www.metopes.fr/metopes.html) stylesheets.

## Compatible OJS Versions

3.3.0 | 3.4.0 | 3.5.0

## Installation

```bash
cd $OJS
git clone -b stable-3_5_0 https://github.com/withanage/xmlConverter.git plugins/generic/xmlConverter
cd plugins/generic/xmlConverter
npm install
npm run build
cd $OJS
php lib/pkp/tools/installPluginVersion.php plugins/generic/xmlConverter/version.xml
```

## Activation

Enable **XML Converter Plugin** in *Settings > Website > Plugins*.

## Development

Rebuild the frontend bundles after changing anything under `resources/js`.
The build also regenerates `registry/uiLocaleKeysBackend.json` from the locale
keys referenced in the Vue sources, so commit the rebuilt assets along with
your changes.

```bash
npm run build          # both bundles
npm run dev:default    # rebuild the default bundle on change
```

Run the unit tests from the OJS root:

```bash
./lib/pkp/lib/vendor/bin/phpunit --bootstrap lib/pkp/tests/phpunit-bootstrap.php \
    plugins/generic/xmlConverter/tests/
```

### Known issue: `npm run lint`

`npm run lint` currently fails with
`Invalid option '--ignore-path' - perhaps you meant '--ignore-pattern'?`.
Invoking `npx eslint` directly fails too, with
`ESLint couldn't find an eslint.config.(js|mjs|cjs) file`.

The plugin depends on ESLint 9 (`^9.20.0`), which requires the flat config
format, but ships the legacy `.eslintrc.cjs` and passes the removed
`--ignore-path` flag. Fixing it means migrating `.eslintrc.cjs` to
`eslint.config.js` and dropping `--ignore-path` from the `lint` script in
`package.json`. Until then linting must be skipped; `npm run build` still
validates that the sources compile.

## Contributors

Jeanette Hatherill, Edith Cannet, Marisa Tutt, Martin Brändle, Dominique Roux, João Martins, Jean-Christophe Souplet, Ipula Ranasinghe, Dulip Withanage
