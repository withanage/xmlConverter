## Introduction

This plugin converts XML-TEI Commons Publishing files to XML-JATS Publishing 1.3 and vice-versa,using Métopes XSLT style sheets.
Its developement was realised in a CRAFT-OA project context https://www.craft-oa.eu/.

## Compatibility

OJS 3.4

## Installation

From the OJS 3.4 release package's root directory:

```bash
$ cd ojs/plugins/generic
$ git clone https://github.com/withanage/teitojats.git
$ php lib/pkp/tools/installPluginVersion.php plugins/generic/teiToJats/version.xml
```

## Activation

Enable the plugin named **TeiToJats Convertor Plugin** in your Dashboard:

*Settings > Website > Plugins*


## Contributors

- Jeanette Hatherill, Coalition Publica
- Edith Cannet, IR Métopes
- Marisa Tutt, PKP
- Martin Brändle, University of Zurich
- Dominique Roux, IR Métopes
- João Martins, OpenEdition
- Jean-Christophe Souplet, OpenEdition
- Ipula Ranasinghe, TIB
- Dulip Withanage, TIB
