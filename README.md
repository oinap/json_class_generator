<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

This package can be used to generate dart classes from a JSON string. It might be handy for large JSON with multiple entities you'd like to capture in a class. 


## Features

The package will create additional classes for every Map<String, dynamic> entry

## Getting started

Use json_generator_annotations package to annotate your JSON String with @JsonClass.
Add this package (json_generator) as a dev_dependency
Then use 
    dart run build_runner build


## Usage

After the classes have been generated, you can freely modify them, such as make fields nullable etc.


