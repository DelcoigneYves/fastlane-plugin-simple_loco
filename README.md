# simple_loco plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-simple_loco)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-simple_loco`, add it to your project by running:

```bash
fastlane add_plugin simple_loco
```

## About simple_loco

A simple implementation for exporting translations from [Loco](https://localise.biz/).

This plugin is heavily inspired by https://github.com/JohnPaulConcierge/fastlane-plugin-loco, but some functionality has been removed and added. This plugin acts primarily as a wrapper implementation around the export single locale API call of Loco (see https://localise.biz/api/docs/export/exportlocale for full details).

There is advanced support for the following platforms:
- Android
- iOS
- Xamarin (with resx resource files)
- Flutter (with arb files)

For the platforms above, an extra adapter is available to create the correct folder and files needed to use the translations.

For other platforms, a default implementation is provided (translation files will be saved like \<provided folder\>/\<provided file name\>.\<locale\>.\<extension\>)

This plugin contains a single action `simple_loco`.

This action uses a configuration file to generate the correct API call.

The config file specifies the following properties:
- locales: List of locales to fetch
- directory: Directory to move translation files to
- platform: Platform for the translations: choice between:
    - Android
    - iOS
    - Xamarin
    - Flutter
    - Custom
- key: Key of the Loco project
- Optional parameters:
  - format
  - filter
  - index
  - source
  - namespace
  - fallback
  - order
  - status
  - printf
  - charset
  - breaks
  - no_comments
  - no_folding

For an explanation of the optional parameters, please see the official API reference: https://localise.biz/api/docs/export/exportlocale

Example of a JSON config file:
```
{
    "locales" : [
      "en",
      "fr",
      "nl",
      "de"
    ],
    "directory" : "src/main/res",
    "platform" : "android",
    "key" : "<Your key here>",
    "fallback" : "en",
    "order": "id",
    "filter": ["android"]
}
```

Or in YAML:
```
locales:
  - en
  - fr
  - nl
  - de
directory: src/main/res
platform: custom
key: <your key here>
fallback: en
order: id
custom_extension: .xml
custom_file_name: strings
```

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
