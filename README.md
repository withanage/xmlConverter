# Introduction

This plug-in is a general conversion plugin for various XML formats in Open Journal Systems (OJS).

xmlConverter plugin supports inter-operability between publication systems that have different export and import XML requirements.

Currently,  JATS XML and TEI-XML , which is supported by OJS, Lodel and Janeway.But the plugin can be extenede to any other XML formats easily.

Both JATS and TEIl formats are widely used in the in publication systems, indexing systems, long-term preservation systems, article production systems and analysis systems in academia.

The plugin may also be used to  plugging to extract or convert XML in the OAI-Interface

The original implementation was carried out as part of the EU Craft-OA project.

Currently supported - OJS Versions
-
- [X] OJS 3.3.0
- [X]  OJS 3.4.0
- []  OJS 3.5.0



# Installation
```bash
git clone https://github.com/withanage/xmlConverter
cd $OJS
php  lib/pkp/tools/installPluginVersion.php plugins/generic/xmlConverter/version.xml
```

# Contributors
- Jeanette Hatherill, Coalition Publica
- Edith Cannet, IR Métopes
- Marisa Tutt, PKP
- Martin Brändle, University of Zurich
- Dominique Roux, IR Métopes
- Ipula Ranasinghe, TIB
- Dulip Withanage, TIB

