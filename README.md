Translator
==========

A simple macOS app that translates Japanese to English, or English to Japanese
naturally by using [webbigdata/C3TR-Adapter_gguf](https://huggingface.co/webbigdata/C3TR-Adapter_gguf)
locally.

The app can be triggered by regular Service on macOS with shortcut key.


Usage
-----

Download the latest pre-build app binary from [Releases](https://github.com/niw/Translator/releases)
page or build it from the source code by following the instructions below.

Note that the pre-build app binary is only ad-hoc signed.
Therefore, you need to click Open Anyway to execute it on
Security & Privacy settings in System Settings.


Build
-----

You need to use the latest macOS and Xcode to build the app.
Open `Applications/Translator.xcodeproj` and build `Translator`
scheme for running.


References
----------

- [webbigdata/C3TR-Adapter_gguf](https://huggingface.co/webbigdata/C3TR-Adapter_gguf)
- [koron/c3tr-client](https://github.com/koron/c3tr-client)
