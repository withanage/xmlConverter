# XML Converter Plugin

Converts JATS-XML and TEI-XML formats in OJS, supporting interoperability between publication systems (OJS, Lodel, Janeway). Developed by [TIB](https://www.tib.eu) with [OpenEdition](https://www.openedition.org/) as part of [Craft-OA](https://www.craft-oa.eu/), using [Métopes](https://www.metopes.fr/metopes.html) stylesheets.

## Compatible OJS Versions

3.3.0 | 3.4.0 | 3.5.0

## Installation

```bash
cd $OJS
git clone -b stable-3_5_0 https://github.com/withanage/xmlConverter.git plugins/generic/xmlConverter
php lib/pkp/tools/installPluginVersion.php plugins/generic/xmlConverter/version.xml
npm install
npm run build         

```

## Activation

Enable **XML Converter Plugin** in *Settings > Website > Plugins*.

## Contributors

Jeanette Hatherill, Edith Cannet, Marisa Tutt, Martin Brändle, Dominique Roux, João Martins, Jean-Christophe Souplet, Ipula Ranasinghe, Dulip Withanage
