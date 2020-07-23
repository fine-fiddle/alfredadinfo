#!/bin/zsh

#your workflow directory path goes here.
WORKFLOWPATH=""

echo "Clearing out old source files. modify this script if you're tired of confirming each";

rm -i -r ./source/*

echo "Copying your live workflow files to the source directory";
cp -r "$WORKFLOWPATH"/* ./source/

echo "removing old .alfredworkflow";
rm AD\ Info.alfredworkflow

echo "Building new .alfredworkflow from the new source files";
cd source 
zip -r AD\ Info.alfredworkflow .
mv AD\ Info.alfredworkflow ../
