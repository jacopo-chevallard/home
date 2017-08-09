#!/bin/bash

git checkout master
if [ $? -ne 0 ]; then
  exit 1
fi

git push origin master
if [ $? -ne 0 ]; then
  exit 1
fi

git push origin develop
if [ $? -ne 0 ]; then
  exit 1
fi

git push origin --tags
if [ $? -ne 0 ]; then
  exit 1
fi

git checkout develop
