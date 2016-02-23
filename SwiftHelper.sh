#!/bin/bash
xcrun swift -sdk $(xcrun --show-sdk-path --sdk macosx) ${@:1}